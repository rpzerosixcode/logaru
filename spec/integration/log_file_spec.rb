# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require "pathname"

RSpec.describe "Logaru::Logger writing to files" do
    it "writes the formatted entry with timestamp, level and progname" do
        with_log_path do |path|
            with_file_logger(path) { |logger| logger.info("started", progname: "web") }

            expect(File.read(path)).to match(/\A\[\d{4}-\d{2}-\d{2} .+\] web INFO: started\n\z/)
        end
    end

    it "creates the missing parent directories" do
        with_log_path("nested/logs/application.log") do |path|
            with_file_logger(path) { |logger| logger.info("message") }

            expect(File.read(path)).to end_with("INFO: message\n")
        end
    end

    it "appends instead of overwriting when the target is a Pathname" do
        with_log_path do |path|
            pathname = Pathname.new(path)

            with_file_logger(pathname) do |logger|
                logger.info("primeira")
                logger.info("segunda")
            end

            expect(File.readlines(path, chomp: true).size).to eq(2)
            expect(File.read(path)).to include("primeira")
            expect(File.read(path)).to include("segunda")
        end
    end

    it "uses a File as the device of a Pathname target" do
        with_log_path do |path|
            pathname = Pathname.new(path)

            with_file_logger(pathname) do |logger|
                logger.info("message")

                expect(logger.device).to be_a(File)
                expect(logger.output).to be(pathname)
            end
        end
    end

    it "keeps the previous entries when the file is closed and reopened" do
        with_log_path do |path|
            with_file_logger(path) do |logger|
                logger.info("antes")
                logger.close
                logger.info("depois")
            end

            expect(File.readlines(path, chomp: true).size).to eq(2)
        end
    end

    it "appends entries written by different loggers" do
        with_log_path do |path|
            with_file_logger(path) { |logger| logger.info("logaru 1") }
            with_file_logger(path) { |logger| logger.info("logaru 2") }

            expect(File.readlines(path, chomp: true).size).to eq(2)
        end
    end

    it "makes every entry visible without closing the file" do
        with_log_path do |path|
            with_file_logger(path) do |logger|
                logger.info("agora")

                expect(File.read(path)).to include("agora")
            end
        end
    end

    it "does not create the file when no entry passes the level" do
        with_log_path do |path|
            with_file_logger(path, level: :error) { |logger| logger.info("ignorada") }

            expect(File.exist?(path)).to be(false)
        end
    end

    it "writes through a File opened by the caller without closing it" do
        with_log_path do |path|
            File.open(path, "a") do |file|
                logger = Logaru::Logger.new(file: file, pattern: proc { |_s, _d, _p, message| "#{message}\n" })

                logger.info("via File")
                logger.close

                expect(file).not_to be_closed
            end

            expect(File.read(path)).to eq("via File\n")
        end
    end

    it "supports external rotation through close and reopen" do
        with_log_path do |path|
            with_file_logger(path) do |logger|
                logger.info("antiga")
                logger.close
                File.rename(path, "#{path}.1")
                logger.info("nova")
            end

            expect(File.read("#{path}.1")).to include("antiga")
            expect(File.readlines(path, chomp: true).size).to eq(1)
            expect(File.read(path)).to include("nova")
        end
    end

    it "writes UTF-8 messages without losing characters" do
        with_log_path do |path|
            with_file_logger(path) { |logger| logger.info("ação concluída") }

            content = File.read(path, encoding: Encoding::UTF_8)

            expect(content).to include("ação concluída")
            expect(content.valid_encoding?).to be(true)
        end
    end

    it "reuses the open handle between writes" do
        with_log_path do |path|
            with_file_logger(path) do |logger|
                logger.info("primeira")
                device = logger.device
                logger.info("segunda")

                expect(logger.device).to be(device)
            end
        end
    end

    it "rejects an output that is neither a path nor a stream" do
        expect { Logaru::Logger.new(file: 42) }.to raise_error(Logaru::InvalidOutputError)
    end
end
# rubocop:enable Metrics/BlockLength
