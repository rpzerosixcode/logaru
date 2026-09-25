# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require "pathname"
require "stringio"

RSpec.describe Logaru::Logger do
    let(:formatter) { instance_double(Logaru::Formatter) }

    before do
        allow(formatter).to receive(:format).and_return("formatted message\n")
    end

    it "writes formatted messages to standard output" do
        logger = described_class.new(formatter: formatter)

        expect { logger.info("message") }.to output("formatted message\n").to_stdout
    end

    it "filters messages below the configured level" do
        logger = described_class.new(formatter: formatter, level: Logaru::Level::WARN)

        expect { logger.info("hidden") }.not_to output.to_stdout
        expect { logger.warn("visible") }.to output("formatted message\n").to_stdout
    end

    it "exposes its configuration" do
        logger = described_class.new(formatter: formatter, level: :error, file: "application.log")

        expect(logger.formatter).to be(formatter)
        expect(logger.level).to eq(Logaru::Level::ERROR)
        expect(logger.output).to eq("application.log")
    end

    it "uses a formatter instance by default" do
        expect(described_class.new.formatter).to be_a(Logaru::Formatter)
    end

    it "uses the default pattern when none is given" do
        expect(described_class.new.formatter.pattern).to be(Logaru::Formatter::DEFAULT_PATTERN)
    end

    it "builds its formatter from a pattern" do
        pattern = proc { |_severity, _datetime, _progname, message| "pattern: #{message}\n" }
        logger = described_class.new(pattern: pattern)

        expect { logger.info("message") }.to output("pattern: message\n").to_stdout
    end

    it "builds its formatter from a block" do
        logger = described_class.new { |_severity, _datetime, _progname, message| "block: #{message}\n" }

        expect { logger.info("message") }.to output("block: message\n").to_stdout
    end

    it "rejects a formatter combined with a pattern" do
        expect { described_class.new(formatter: formatter, pattern: proc {}) }.to raise_error(
            Logaru::InvalidFormatterError,
            /either formatter or pattern/,
        )
    end

    it "rejects a formatter combined with a block" do
        expect { described_class.new(formatter: formatter) { |*_arguments| "" } }.to raise_error(
            Logaru::InvalidFormatterError,
            /either formatter or pattern/,
        )
    end

    it "writes entries with the default formatter" do
        with_log_path do |path|
            with_file_logger(path) { |logger| logger.info("started") }

            expect(File.read(path)).to end_with("INFO: started\n")
        end
    end

    it "creates the parent directories of the log file" do
        with_log_path("nested/logs/application.log") do |path|
            with_file_logger(path, formatter: formatter) { |logger| logger.info("message") }

            expect(File.read(path)).to eq("formatted message\n")
        end
    end

    it "appends formatted messages to a file" do
        with_log_path do |path|
            with_file_logger(path, formatter: formatter) do |logger|
                logger.error("message", progname: "worker")
            end

            expect(File.read(path)).to eq("formatted message\n")
        end
    end

    it "reuses the log file between writes" do
        with_log_path do |path|
            with_file_logger(path, formatter: formatter) do |logger|
                logger.info("first")
                device = logger.device
                logger.info("second")

                expect(logger.device).to be(device)
            end

            expect(File.read(path)).to eq("formatted message\nformatted message\n")
        end
    end

    it "flushes every write by default" do
        with_log_path do |path|
            with_file_logger(path, formatter: formatter) do |logger|
                expect(logger.device.sync).to be(true)
            end
        end
    end

    it "allows the synchronization to be disabled" do
        with_log_path do |path|
            with_file_logger(path, formatter: formatter, sync: false) do |logger|
                expect(logger.device.sync).to be(false)
            end
        end
    end

    it "reopens the log file after it is closed" do
        with_log_path do |path|
            with_file_logger(path, formatter: formatter) do |logger|
                logger.info("before")
                logger.close
                logger.info("after")
            end

            expect(File.read(path)).to eq("formatted message\nformatted message\n")
        end
    end

    it "accepts a pathname" do
        with_log_path do |path|
            pathname = Pathname.new(path)

            with_file_logger(pathname, formatter: formatter) { |logger| logger.info("message") }

            expect(pathname.read).to eq("formatted message\n")
        end
    end

    it "writes to an output stream" do
        output = StringIO.new
        logger = described_class.new(formatter: formatter, file: output)

        logger.info("message")

        expect(output.string).to eq("formatted message\n")
    end

    it "does not close streams owned by the caller" do
        output = StringIO.new
        logger = described_class.new(formatter: formatter, file: output)

        logger.info("message")
        logger.close

        expect(output).not_to be_closed
        expect(output.string).to eq("formatted message\n")
    end

    it "supports the unknown severity" do
        output = StringIO.new
        logger = described_class.new(formatter: formatter, file: output)

        logger.unknown("message")

        expect(output.string).to eq("formatted message\n")
        expect(formatter).to have_received(:format).with(
            Logaru::Level::UNKNOWN,
            kind_of(Time),
            nil,
            "message",
        )
    end

    it "logs through the generic entry point with a textual severity" do
        output = StringIO.new
        logger = described_class.new(formatter: formatter, file: output, level: :warn)

        logger.log("WARN", "message", progname: "web")

        expect(formatter).to have_received(:format).with(
            Logaru::Level::WARN,
            kind_of(Time),
            "web",
            "message",
        )
        expect(output.string).to eq("formatted message\n")
    end

    it "filters entries passed to the generic entry point" do
        output = StringIO.new
        logger = described_class.new(formatter: formatter, file: output, level: :error)

        logger.log(:info, "hidden")

        expect(output.string).to be_empty
        expect(formatter).not_to have_received(:format)
    end

    it "rejects an invalid formatter" do
        expect { described_class.new(formatter: Object.new) }.to raise_error(
            Logaru::InvalidFormatterError,
            /respond to #format/,
        )
    end

    it "rejects an invalid output" do
        expect { described_class.new(formatter: formatter, file: 42) }.to raise_error(
            Logaru::InvalidOutputError,
            /path or an object responding to #write/,
        )
    end

    it "rejects an invalid configured level" do
        expect { described_class.new(formatter: formatter, level: "verbose") }.to raise_error(
            Logaru::InvalidLevelError,
        )
    end
end
# rubocop:enable Metrics/BlockLength
