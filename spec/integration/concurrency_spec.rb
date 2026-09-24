# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require "stringio"

RSpec.describe "Logaru::Logger under concurrency" do
    let(:pattern) { proc { |_severity, _datetime, _progname, message| "#{message}\n" } }

    # Builds a stream that records whether two writes are in progress at once.
    def overlapping_probe(overlapped)
        in_write = false

        Object.new.tap do |device|
            device.define_singleton_method(:write) do |message|
                overlapped.call if in_write
                in_write = true
                sleep 0.002
                in_write = false
                message.bytesize
            end
        end
    end

    # Spawns +threads+ threads writing +rounds+ entries each and waits for them.
    def write_concurrently(logger, threads:, rounds:)
        workers = Array.new(threads) do |index|
            Thread.new { rounds.times { |round| logger.info("t#{index}-#{round}") } }
        end

        workers.each(&:join)
    end

    it "serializes writes performed by different threads" do
        overlapped = false
        logger = Logaru::Logger.new(file: overlapping_probe(-> { overlapped = true }), pattern: pattern)

        write_concurrently(logger, threads: 4, rounds: 10)

        expect(overlapped).to be(false)
    end

    it "writes every entry of concurrent threads to a stream" do
        output = StringIO.new
        logger = Logaru::Logger.new(file: output, pattern: pattern)

        write_concurrently(logger, threads: 8, rounds: 25)

        lines = output.string.lines

        expect(lines.size).to eq(200)
        expect(lines).to all(match(/\At\d+-\d+\n\z/))
    end

    it "opens the log file once for concurrent writers" do
        allow(File).to receive(:open).and_call_original

        with_log_path do |path|
            with_file_logger(path, pattern: pattern) { |logger| write_concurrently(logger, threads: 8, rounds: 25) }

            expect(File).to have_received(:open).once
            expect(File.readlines(path, chomp: true).size).to eq(200)
        end
    end

    it "keeps every entry when close is called while other threads write" do
        with_log_path do |path|
            with_file_logger(path, pattern: pattern) do |logger|
                writers = Array.new(4) do |index|
                    Thread.new do
                        10.times do |round|
                            logger.info("w#{index}-#{round}")
                            Thread.pass
                        end
                    end
                end
                closer = Thread.new do
                    5.times do
                        logger.close
                        Thread.pass
                    end
                end

                (writers << closer).each(&:join)
            end

            expect(File.readlines(path, chomp: true).size).to eq(40)
        end
    end
end
# rubocop:enable Metrics/BlockLength
