# frozen_string_literal: true

require "lso"

RSpec.describe LSO do
    it "exposes a version number" do
        expect(LSO::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end

    it "exposes the gem root directory" do
        expect(LSO.root).to eq(File.expand_path("../..", __dir__))
    end
end
