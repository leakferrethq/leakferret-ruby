# frozen_string_literal: true

require 'json'
require 'open3'

module Leakferret
  # Thin shell-out wrapper. Each public method invokes the binary with
  # `--format json` and parses the resulting array.
  class Client
    def scan(path, exclude: [], only: nil, show_fixtures: false)
      run(['scan', path, '--format', 'json'] + format_flags(exclude:, only:, show_fixtures:))
    end

    def verify(path, mode: 'best-effort', timeout: 10, **opts)
      run(['verify', path, '--format', 'json', '--verify-mode', mode,
           '--verifier-timeout-secs', timeout.to_s] + format_flags(**opts))
    end

    def rewrite(path, apply: false, backend: 'env', **opts)
      args = ['rewrite', path, '--format', 'json', '--backend', backend]
      args << '--apply' if apply
      run(args + format_flags(**opts))
    end

    private

    def format_flags(exclude: [], only: nil, show_fixtures: false)
      flags = []
      Array(exclude).each { |g| flags.push('--exclude', g) }
      Array(only).each   { |p| flags.push('--only',    p) }
      flags << '--show-fixtures' if show_fixtures
      flags
    end

    def run(args)
      out, err, status = Open3.capture3(Binary.path, *args)
      unless [0, 1].include?(status.exitstatus)
        raise BinaryInvocationError.new(
          "leakferret exited with #{status.exitstatus}",
          exit_status: status.exitstatus,
          stderr: err,
        )
      end
      JSON.parse(out.strip.empty? ? '[]' : out)
    end
  end
end
