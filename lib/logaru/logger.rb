# frozen_string_literal: true

require_relative "errors"
require_relative "level"
require_relative "formatter"

module Logaru
    # Writes log entries through a formatter to the console or a file.
    class Logger
        # Initializes the logger with a formatter, level and optional file.
        def initialize(formatter: Formatter, level: Level::DEBUG, file: nil)
            @formatter = formatter
            @level = Level.coerce(level)
            @file = file
            validate_formatter!
        end

        # Logs a message using the configured formatter.
        def log(severity, message, progname: nil)
            severity = Level.coerce(severity)
            return if severity < @level

            formatted = @formatter.format(severity, Time.now, progname, message)
            write(formatted)
        end

        # Logs a debug message.
        def debug(message, progname: nil)
            log(Level::DEBUG, message, progname:)
        end

        # Logs an informational message.
        def info(message, progname: nil)
            log(Level::INFO, message, progname:)
        end

        # Logs a warning message.
        def warn(message, progname: nil)
            log(Level::WARN, message, progname:)
        end

        # Logs an error message.
        def error(message, progname: nil)
            log(Level::ERROR, message, progname:)
        end

        # Logs a fatal error message.
        def fatal(message, progname: nil)
            log(Level::FATAL, message, progname:)
        end

        # Logs a message with an unknown severity.
        def unknown(message, progname: nil)
            log(Level::UNKNOWN, message, progname:)
        end

        private

        def validate_formatter!
            return if @formatter.respond_to?(:format)

            raise InvalidFormatterError, "formatter must respond to #format"
        end

        def write(message)
            @file ? write_to_file(message) : $stdout.write(message)
        end

        # Appends the formatted message to the configured file or stream.
        def write_to_file(message)
            return @file.write(message) if @file.respond_to?(:write)

            File.open(@file, "a") { |file| file.write(message) }
        end
    end
end
