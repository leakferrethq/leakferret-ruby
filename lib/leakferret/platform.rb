# frozen_string_literal: true

require 'rbconfig'

require_relative 'error'

module Leakferret
  module Platform
    module_function

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

    def binary_name
      windows? ? 'leakferret.exe' : 'leakferret'
    end

    def windows?
      RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    end
  end
end
