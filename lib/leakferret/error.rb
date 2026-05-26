# frozen_string_literal: true

module Leakferret
  class Error < StandardError; end
  class BinaryNotFoundError < Error; end
  class BinaryInvocationError < Error
    attr_reader :exit_status, :stderr

    def initialize(message, exit_status:, stderr:)
      super(message)
      @exit_status = exit_status
      @stderr = stderr
    end
  end
end
