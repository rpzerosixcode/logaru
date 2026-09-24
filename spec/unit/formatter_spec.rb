# frozen_string_literal: true

RSpec.describe Logaru::Formatter do
    let(:datetime) { Time.utc(2026, 9, 24, 12, 34, 56) }

    around do |example|
        original_pattern = described_class.pattern
        example.run
    ensure
        described_class.pattern(&original_pattern)
    end

    it "formats a message with the default pattern" do
        expect(described_class.format(Logaru::Level::INFO, datetime, nil, "started")).to eq(
            "[2026-09-24 12:34:56 UTC] INFO: started\n",
        )
    end

    it "includes a program name when provided" do
        expect(described_class.format(Logaru::Level::ERROR, datetime, "worker", "failed")).to eq(
            "[2026-09-24 12:34:56 UTC] worker ERROR: failed\n",
        )
    end

    it "allows the pattern to be replaced" do
        described_class.pattern { |_severity, _datetime, _progname, message| "custom: #{message}\n" }
        expect(described_class.format(Logaru::Level::DEBUG, datetime, nil, "message")).to eq(
            "custom: message\n",
        )
    end
end
