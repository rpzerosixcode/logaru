# frozen_string_literal: true

module Logaru
    # Base class for errors raised by Logaru.
    class Error < StandardError; end

    # Raised when a logger is configured with an invalid formatter.
    class InvalidFormatterError < Error; end

    # Raised when a logger receives an unsupported severity.
    class InvalidLevelError < Error; end
end
