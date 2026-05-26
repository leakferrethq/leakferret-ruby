# frozen_string_literal: true

require 'rbconfig'

module Leakferret
  module Platform
    module_function

    def triple
      cpu = case RbConfig::CONFIG['host_cpu']
            when /x86_64|amd64/ then 'x86_64'
            when /aarch64|arm64/ then 'aarch64'
            else
              raise Error, "unsupported CPU: #{RbConfig::CONFIG['host_cpu']}"
            end

      case RbConfig::CONFIG['host_os']
      when /mswin|mingw|cygwin/ then "#{cpu}-pc-windows-gnu"
      when /darwin/             then "#{cpu}-apple-darwin"
      when /linux/              then "#{cpu}-unknown-linux-gnu"
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
