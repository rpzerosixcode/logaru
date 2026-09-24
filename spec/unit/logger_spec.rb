# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require "stringio"
require "tempfile"

RSpec.describe Logaru::Logger do
    let(:formatter) { class_double(Logaru::Formatter) }

    before do
        allow(formatter).to receive(:format).and_return("formatted message\n")
    end

    it "writes formatted messages to standard output" do
        logger = described_class.new(formatter:)

        expect { logger.info("message") }.to output("formatted message\n").to_stdout
    end

    it "filters messages below the configured level" do
        logger = described_class.new(formatter:, level: Logaru::Level::WARN)

        expect { logger.info("hidden") }.not_to output.to_stdout
        expect { logger.warn("visible") }.to output("formatted message\n").to_stdout
    end

    it "appends formatted messages to a file" do
        Tempfile.create("logaru") do |file|
            logger = described_class.new(formatter:, file: file.path)
            logger.error("message", progname: "worker")

            expect(File.read(file.path)).to eq("formatted message\n")
        end
    end

    it "writes to an output stream" do
        output = StringIO.new
        logger = described_class.new(formatter:, file: output)

        logger.info("message")

        expect(output.string).to eq("formatted message\n")
    end

    it "supports the unknown severity" do
        output = StringIO.new
        logger = described_class.new(formatter:, file: output)

        logger.unknown("message")

        expect(output.string).to eq("formatted message\n")
        expect(formatter).to have_received(:format).with(
            Logaru::Level::UNKNOWN,
            kind_of(Time),
            nil,
            "message",
        )
    end

    it "rejects an invalid formatter" do
        expect { described_class.new(formatter: Object.new) }.to raise_error(
            Logaru::InvalidFormatterError,
            /respond to #format/,
        )
    end

    it "rejects an invalid configured level" do
        expect { described_class.new(formatter:, level: "verbose") }.to raise_error(
            Logaru::InvalidLevelError,
        )
    end
end
# rubocop:enable Metrics/BlockLength
