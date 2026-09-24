# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

RSpec.describe Logaru::Formatter do
    let(:datetime) { Time.utc(2026, 9, 24, 12, 34, 56) }
    let(:formatter) { described_class.new }

    describe "#format" do
        it "formats a message with the default pattern" do
            expect(formatter.format(Logaru::Level::INFO, datetime, nil, "started")).to eq(
                "[2026-09-24 12:34:56 UTC] INFO: started\n",
            )
        end

        it "includes a program name when provided" do
            expect(formatter.format(Logaru::Level::ERROR, datetime, "worker", "failed")).to eq(
                "[2026-09-24 12:34:56 UTC] worker ERROR: failed\n",
            )
        end

        it "keeps the pattern isolated between instances" do
            custom = described_class.new do |_severity, _datetime, _progname, message|
                "custom: #{message}\n"
            end

            expect(custom.format(Logaru::Level::DEBUG, datetime, nil, "message")).to eq("custom: message\n")
            expect(formatter.format(Logaru::Level::DEBUG, datetime, nil, "message")).to eq(
                "[2026-09-24 12:34:56 UTC] DEBUG: message\n",
            )
        end

        it "accepts a pattern as an option" do
            pattern = proc { |_severity, _datetime, _progname, message| "custom: #{message}\n" }
            formatter = described_class.new(pattern: pattern)

            expect(formatter.format(Logaru::Level::DEBUG, datetime, nil, "message")).to eq("custom: message\n")
        end

        it "prefers a block over the pattern option" do
            pattern = proc { |_severity, _datetime, _progname, _message| "option\n" }
            formatter = described_class.new(pattern: pattern) { |*_arguments| "block\n" }

            expect(formatter.format(Logaru::Level::DEBUG, datetime, nil, "message")).to eq("block\n")
        end
    end

    describe "pattern validation" do
        it "exposes the configured pattern" do
            expect(formatter.pattern).to be_a(Proc)
        end

        it "accepts lambdas" do
            pattern = ->(_severity, _datetime, _progname, message) { "#{message}\n" }
            formatter = described_class.new(pattern: pattern)

            expect(formatter.format(Logaru::Level::INFO, datetime, nil, "lambda")).to eq("lambda\n")
        end

        it "accepts variadic patterns" do
            pattern = proc { |*arguments| "#{arguments.size}\n" }
            formatter = described_class.new(pattern: pattern)

            expect(formatter.format(Logaru::Level::INFO, datetime, nil, "message")).to eq("4\n")
        end

        it "accepts patterns with optional parameters" do
            pattern = proc { |_severity, _datetime, _progname, message = nil| "#{message}\n" }
            formatter = described_class.new(pattern: pattern)

            expect(formatter.format(Logaru::Level::INFO, datetime, nil, "message")).to eq("message\n")
        end

        it "accepts callable objects that do not expose their parameters" do
            pattern = Class.new do
                def call(_severity, _datetime, _progname, message)
                    "#{message}\n"
                end
            end.new
            formatter = described_class.new(pattern: pattern)

            expect(formatter.format(Logaru::Level::INFO, datetime, nil, "callable")).to eq("callable\n")
        end

        it "rejects patterns that cannot receive the log arguments" do
            pattern = proc { |_severity, message| "#{message}\n" }

            expect { described_class.new(pattern: pattern) }.to raise_error(
                Logaru::InvalidPatternError,
                /pattern must accept 4 arguments/,
            )
        end

        it "rejects lambdas with the wrong arity" do
            pattern = ->(_severity, _progname) { "invalid\n" }

            expect { described_class.new(pattern: pattern) }.to raise_error(
                Logaru::InvalidPatternError,
                /pattern must accept 4 arguments/,
            )
        end

        it "rejects values that are not callable" do
            expect { described_class.new(pattern: "verbose") }.to raise_error(
                Logaru::InvalidPatternError,
                /pattern must respond to #call/,
            )
        end
    end
end
# rubocop:enable Metrics/BlockLength
