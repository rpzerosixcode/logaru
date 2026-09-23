# frozen_string_literal: true

require_relative "lso/version"

# Entry point of the Logstyout library.
module LSO
    class << self
        # Returns the absolute path to the gem root directory.
        def root
            File.expand_path("..", __dir__)
        end
    end
end
