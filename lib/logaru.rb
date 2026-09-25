# frozen_string_literal: true

require_relative "logaru/version"
require_relative "logaru/errors"
require_relative "logaru/level"
require_relative "logaru/formatter"
require_relative "logaru/logger"

# Entry point of the Logaru library.
module Logaru
    class << self
        # Returns the absolute path to the gem root directory.
        def root
            File.expand_path("..", __dir__)
        end
    end
end
