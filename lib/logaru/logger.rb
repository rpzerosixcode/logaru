# frozen_string_literal: true

require "fileutils"

require_relative "errors"
require_relative "level"
require_relative "formatter"

module Logaru
    # Writes log entries through a formatter to the console or a file.
    class Logger
        attr_reader :formatter, :level, :output

        # Initializes the logger with a formatter, level and optional output.
        #
        # +file+ accepts a path (String or Pathname) or any object responding to
        # #write, such as an open File or a StringIO. When it is omitted, entries
        # are written to $stdout. +sync+ controls whether every write is flushed,
        # which defaults to true so that log files are always up to date.
        def initialize(formatter: nil, level: Level::DEBUG, file: nil, sync: true)
            @level = Level.coerce(level)
            @output = file
            @sync = sync
            @formatter = formatter || Formatter.new
            @device = nil
            @owned = false
            validate_formatter!
            validate_output!
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

        # Returns the IO used for writing, opening the log file on first use.
        def device
            return $stdout if @output.nil?

            @device ||= open_device
        end

        # Closes the log file opened by the logger. The file is reopened on the
        # next write, which keeps external log rotation working. Streams and
        # objects provided through +file+ are left untouched.
        def close
            @device.close if @owned && @device.respond_to?(:close)
            @device = nil
            @owned = false
        end

        private

        def validate_formatter!
            return if @formatter.respond_to?(:format)

            raise InvalidFormatterError, "formatter must respond to #format (use Logaru::Formatter.new)"
        end

        def validate_output!
            return if @output.nil?
            return if @output.is_a?(String) || @output.respond_to?(:to_path) || @output.respond_to?(:write)

            raise InvalidOutputError, "output must be a path or an object responding to #write"
        end

        def write(message)
            device.write(message)
        end

        # Returns the target of the log entries, opening the file and reusing it
        # on the following writes.
        def open_device
            return @output if @output.respond_to?(:write)

            @owned = true
            open_file(@output)
        end

        # Opens (creating, when needed, the parent directories) the log file in
        # append mode. The handle is kept open and released by #close, so entries
        # are appended to the same file between writes.
        def open_file(path)
            path = path.to_path if path.respond_to?(:to_path)
            FileUtils.mkdir_p(File.dirname(path))
            file = File.open(path, "a") # rubocop:disable Style/FileOpen
            file.sync = @sync
            file
        end
    end
end
