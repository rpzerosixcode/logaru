# frozen_string_literal: true

require "fileutils"
require "pathname"

require_relative "errors"
require_relative "level"
require_relative "formatter"

module Logaru
    # Writes log entries through a formatter to the console or a file.
    class Logger
        attr_reader :formatter, :level, :output

        # Initializes the logger with a level and optional output and formatting.
        #
        # +file+ accepts a path (String or Pathname) or any object responding to
        # #write, such as an open File or a StringIO. When it is omitted, entries
        # are written to $stdout. +sync+ controls whether every write is flushed,
        # which defaults to true so that log files are always up to date.
        #
        # Formatting is handled by a Logaru::Formatter built here. Pass +pattern+
        # (or a block) to configure it, or +formatter+ to inject an instance —
        # never both.
        #
        # Entries are written while holding a mutex, so the same logger can be
        # shared between threads. The formatter pattern is called outside the
        # lock, so it must not depend on mutable shared state.
        def initialize(formatter: nil, level: Level::DEBUG, file: nil, sync: true, pattern: nil, &block)
            validate_formatter_options!(formatter, pattern, block)
            @level = Level.coerce(level)
            @output = file
            @sync = sync
            @formatter = formatter || build_formatter(pattern, &block)
            @resolved_device = nil
            @owned = false
            @mutex = Mutex.new
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
            @mutex.synchronize { resolved_device }
        end

        # Closes the log file opened by the logger. The file is reopened on the
        # next write, which keeps external log rotation working. Streams and
        # objects provided through +file+ are left untouched.
        #
        # Safe to call from another thread: it waits for the write in progress
        # before releasing the handle.
        def close
            @mutex.synchronize do
                @resolved_device.close if @owned && @resolved_device.respond_to?(:close)
                @resolved_device = nil
                @owned = false
            end
        end

        private

        # Rejects a formatter injected together with a pattern or a block.
        def validate_formatter_options!(formatter, pattern, block)
            return unless formatter && (pattern || block)

            raise InvalidFormatterError, "pass either formatter or pattern, not both"
        end

        # Builds the formatter used when none is injected, honoring a pattern.
        def build_formatter(pattern, &)
            Formatter.new(pattern: pattern || Formatter::DEFAULT_PATTERN, &)
        end

        def validate_formatter!
            return if @formatter.respond_to?(:format)

            raise InvalidFormatterError, "formatter must respond to #format (use Logaru::Formatter.new)"
        end

        def validate_output!
            return if @output.nil? || path_like?(@output) || @output.respond_to?(:write)

            raise InvalidOutputError, "output must be a path or an object responding to #write"
        end

        def write(message)
            @mutex.synchronize { resolved_device.write(message) }
        end

        # Returns the target of the log entries, opening the log file on first
        # use and reusing it on the following writes. Callers must hold the mutex
        # so the file is opened (and the parent directories created) only once.
        def resolved_device
            return $stdout if @output.nil?

            @resolved_device ||= open_device
        end

        # Returns true when the value stands for a file path instead of a stream.
        #
        # Pathname is handled explicitly because it responds to #write, and that
        # method writes the whole file in one call: treating a Pathname as a
        # stream would make every entry overwrite the log file.
        def path_like?(value)
            value.is_a?(String) || value.is_a?(Pathname) || (!value.respond_to?(:write) && value.respond_to?(:to_path))
        end

        # Opens the log file for path targets and returns caller-owned streams as
        # they are.
        def open_device
            return @output unless path_like?(@output)

            @owned = true
            open_file(@output)
        end

        # Opens (creating, when needed, the parent directories) the log file in
        # append mode. The handle is kept open and released by #close, so entries
        # are appended to the same file between writes.
        def open_file(path)
            path = path.to_path if path.respond_to?(:to_path)
            FileUtils.mkdir_p(File.dirname(path))
            # The handle is intentionally kept open until #close, so the block
            # form of File.open would defeat the reuse between writes.
            file = File.open(path, "a") # rubocop:disable Style/FileOpen
            file.sync = @sync
            file
        end
    end
end
