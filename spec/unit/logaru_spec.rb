# frozen_string_literal: true

require "logaru"

RSpec.describe Logaru do
    it "exposes a version number" do
        expect(Logaru::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end

    it "exposes the gem root directory" do
        expect(Logaru.root).to eq(File.expand_path("../..", __dir__))
    end
end
