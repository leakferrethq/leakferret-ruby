# frozen_string_literal: true

require 'rbconfig'

require_relative 'error'

module Leakferret
  # Host detection for picking the right release asset. Maps the running
  # Ruby's `RbConfig` host to a Rust target triple and binary name.
  #
  # @api private
  module Platform
    module_function

    # The Rust target triple for the current host (e.g.
    # `x86_64-unknown-linux-gnu`).
    #
    # @return [String] the target triple
    # @raise [Error] on an unsupported CPU or OS, or aarch64-linux (no asset yet)
    def triple
      cpu = case RbConfig::CONFIG['host_cpu']
            when /x86_64|amd64|x64/ then 'x86_64'
            when /aarch64|arm64/ then 'aarch64'
            else
              raise Error, "unsupported CPU: #{RbConfig::CONFIG['host_cpu']}"
            end

      case RbConfig::CONFIG['host_os']
      when /mswin|mingw|cygwin/ then "#{cpu}-pc-windows-msvc"
      when /darwin/             then "#{cpu}-apple-darwin"
      when /linux/
        # No aarch64-linux release asset yet (v0.1.0 ships x86_64 only).
        raise Error, 'aarch64-linux has no prebuilt binary yet; build from source' if cpu == 'aarch64'

        "#{cpu}-unknown-linux-gnu"
      else
        raise Error, "unsupported OS: #{RbConfig::CONFIG['host_os']}"
      end
    end

    # Executable name for the current OS.
    # @return [String] `"leakferret.exe"` on Windows, otherwise `"leakferret"`
    def binary_name
      windows? ? 'leakferret.exe' : 'leakferret'
    end

    # @return [Integer, nil] truthy when the host OS is Windows
    def windows?
      RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    end
  end
end
