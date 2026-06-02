# frozen_string_literal: true

module Leakferret
  # Base class for every error this gem raises. Rescue this to catch them all.
  class Error < StandardError; end

  # Raised when the native binary cannot be located or downloaded (no pinned
  # checksum for the platform, a failed download, or a bad `LEAKFERRET_BIN`).
  class BinaryNotFoundError < Error; end

  # Raised when the binary runs but exits with an unexpected status (anything
  # other than 0 for a clean run or 1 for findings present).
  class BinaryInvocationError < Error
    # @return [Integer] the binary's process exit status
    attr_reader :exit_status

    # @return [String] captured standard error from the failed invocation
    attr_reader :stderr

    # @param message [String] human-readable error message
    # @param exit_status [Integer] the binary's exit status
    # @param stderr [String] captured standard error
    def initialize(message, exit_status:, stderr:)
      super(message)
      @exit_status = exit_status
      @stderr = stderr
    end
  end
end
