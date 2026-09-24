# frozen_string_literal: true

require_relative "errors"

module Logaru
    # Numeric values for the supported log severities.
    class Level
        DEBUG   = 0
        INFO    = 1
        WARN    = 2
        ERROR   = 3
        FATAL   = 4
        UNKNOWN = 5

        # Maps level names to their numeric values.
        LEVELS = {
            "debug" => DEBUG,
            "info" => INFO,
            "warn" => WARN,
            "error" => ERROR,
            "fatal" => FATAL,
            "unknown" => UNKNOWN,
        }.freeze

        class << self
            # Converts a numeric or textual level to its numeric value.
            def coerce(value)
                return value if LEVELS.value?(value)

                name = value.to_s.downcase
                return LEVELS.fetch(name) if LEVELS.key?(name)

                raise InvalidLevelError, "unsupported log level: #{value.inspect}"
            end

            # Returns the canonical name for a numeric or textual level.
            def name_for(value)
                LEVELS.key(coerce(value))
            end
        end
    end
end
