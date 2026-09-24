# frozen_string_literal: true

RSpec.describe Logaru::Level do
    it "exposes the supported numeric severities" do
        expect(described_class::LEVELS).to eq(
            "debug" => described_class::DEBUG,
            "info" => described_class::INFO,
            "warn" => described_class::WARN,
            "error" => described_class::ERROR,
            "fatal" => described_class::FATAL,
            "unknown" => described_class::UNKNOWN,
        )
    end

    it "normalizes numeric and textual severities" do
        expect(described_class.coerce(described_class::WARN)).to eq(described_class::WARN)
        expect(described_class.coerce("WARN")).to eq(described_class::WARN)
        expect(described_class.name_for(:error)).to eq("error")
    end

    it "rejects unsupported severities" do
        expect { described_class.coerce("verbose") }.to raise_error(
            Logaru::InvalidLevelError,
            /unsupported log level/,
        )
    end
end
