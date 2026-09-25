# frozen_string_literal: true

require "tmpdir"

# Helpers for the specs that write log entries to files.
module LogFileHelpers
    # Yields the path of a log file inside a temporary directory that is removed
    # when the block returns.
    def with_log_path(name = "application.log")
        Dir.mktmpdir("logaru") do |directory|
            yield File.join(directory, name)
        end
    end

    # Yields a logger writing to +path+ and closes it when the block returns, so
    # the file handle is released before temporary files are removed. Keeping
    # the handle open would prevent the removal on Windows.
    def with_file_logger(path, **)
        logger = Logaru::Logger.new(file: path, **)
        yield logger
    ensure
        logger&.close
    end
end

RSpec.configure do |config|
    config.include LogFileHelpers
end
