# frozen_string_literal: true

require_relative "errors"
require_relative "level"

module Logaru
    # Formats log entries using a configurable pattern.
    class Formatter
        # Number of arguments every pattern must be able to receive.
        PATTERN_ARITY = 4

        # Pattern used when the formatter is instantiated without one.
        DEFAULT_PATTERN = proc do |severity, datetime, progname, message|
            prefix = progname ? "#{progname} " : ""
            "[#{datetime}] #{prefix}#{Level.name_for(severity).upcase}: #{message}\n"
        end

        attr_reader :pattern

        # Initializes the formatter with an optional pattern. A block takes
        # precedence over the +pattern+ option, so both
        # Formatter.new(pattern: proc { ... }) and Formatter.new { ... } work.
        def initialize(pattern: DEFAULT_PATTERN, &block)
            @pattern = block || pattern
            validate_pattern!
        end

        # Formats a log entry using the configured pattern.
        def format(severity, datetime, progname, message)
            @pattern.call(severity, datetime, progname, message)
        end

        private

        def validate_pattern!
            raise InvalidPatternError, "pattern must respond to #call" unless @pattern.respond_to?(:call)
            return if compatible_arity?

            raise InvalidPatternError, "pattern must accept #{PATTERN_ARITY} arguments"
        end

        # Returns true when the pattern can be called with the log arguments.
        def compatible_arity?
            return true unless @pattern.respond_to?(:parameters)

            parameters = @pattern.parameters
            required = parameters.count { |type, _name| type == :req }
            optional = parameters.count { |type, _name| type == :opt }
            variadic = parameters.any? { |type, _name| type == :rest }

            required <= PATTERN_ARITY && (variadic || required + optional >= PATTERN_ARITY)
        end
    end
end
