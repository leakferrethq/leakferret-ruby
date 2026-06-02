# frozen_string_literal: true

require 'json'
require 'open3'

module Leakferret
  # Thin shell-out wrapper around the native binary. Each public method invokes
  # `leakferret <verb> --format json` and parses the resulting array. You
  # normally call the module-level {Leakferret.scan}, {Leakferret.verify}, and
  # {Leakferret.rewrite} helpers instead of constructing this directly.
  class Client
    # Run a scan-only pass (regex pre-filter, offline).
    #
    # @param path [String] file or directory to scan
    # @param exclude [Array<String>] glob(s) to skip
    # @param only [Array<String>, String, nil] restrict the scan to these path(s)
    # @param show_fixtures [Boolean] include catalog fixtures in the result
    # @return [Array<Hash>] candidate finding hashes
    # @raise [BinaryInvocationError] on an unexpected exit status
    def scan(path, exclude: [], only: nil, show_fixtures: false)
      run(['scan', path, '--format', 'json'] + format_flags(exclude:, only:, show_fixtures:))
    end

    # Run scan + classify + provider verification.
    #
    # @param path [String] file or directory to scan
    # @param mode [String] verify mode passed to `--verify-mode`
    # @param timeout [Integer] per-verifier timeout in seconds
    # @option opts [Array<String>] :exclude glob(s) to skip
    # @option opts [Array<String>, String] :only restrict the scan to these path(s)
    # @option opts [Boolean] :show_fixtures include catalog fixtures
    # @return [Array<Hash>] findings with verification and verdict filled in
    # @raise [BinaryInvocationError] on an unexpected exit status
    def verify(path, mode: 'best-effort', timeout: 10, **opts)
      run(['verify', path, '--format', 'json', '--verify-mode', mode,
           '--verifier-timeout-secs', timeout.to_s] + format_flags(**opts))
    end

    # Run scan + classify + rewrite proposal.
    #
    # @param path [String] file or directory to scan
    # @param apply [Boolean] write the rewrites in place when true
    # @param backend [String] rewrite backend (e.g. `env`, `doppler`)
    # @option opts [Array<String>] :exclude glob(s) to skip
    # @option opts [Array<String>, String] :only restrict the scan to these path(s)
    # @return [Array<Hash>] findings, each with a proposed replacement
    # @raise [BinaryInvocationError] on an unexpected exit status
    def rewrite(path, apply: false, backend: 'env', **opts)
      args = ['rewrite', path, '--format', 'json', '--backend', backend]
      args << '--apply' if apply
      run(args + format_flags(**opts))
    end

    private

    # Build the shared `--exclude` / `--only` / `--show-fixtures` flag list.
    #
    # @return [Array<String>] CLI flags
    # @api private
    def format_flags(exclude: [], only: nil, show_fixtures: false)
      flags = []
      Array(exclude).each { |g| flags.push('--exclude', g) }
      Array(only).each   { |p| flags.push('--only',    p) }
      flags << '--show-fixtures' if show_fixtures
      flags
    end

    # Invoke the binary and parse its JSON output. Exit codes 0 (clean) and 1
    # (findings present) are both treated as success; any other status raises.
    #
    # @param args [Array<String>] argv passed to the binary
    # @return [Array<Hash>] the parsed findings (empty array when output is blank)
    # @raise [BinaryInvocationError] if the binary exits with a status other than 0 or 1
    # @api private
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
