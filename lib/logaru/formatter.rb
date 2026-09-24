# frozen_string_literal: true

require_relative "level"

module Logaru
    # Formats log entries using a configurable pattern.
    class Formatter
        @pattern = proc do |severity, datetime, progname, message|
            prefix = progname ? "#{progname} " : ""
            "[#{datetime}] #{prefix}#{Level.name_for(severity).upcase}: #{message}\n"
        end

        class << self
            # Gets the current pattern or replaces it when a block is given.
            def pattern(&block)
                return @pattern unless block

                @pattern = block
            end

            # Formats a log entry using the configured pattern.
            def format(severity, datetime, progname, message)
                @pattern.call(severity, datetime, progname, message)
            end
        end
    end
end
