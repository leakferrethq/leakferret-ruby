# frozen_string_literal: true

require 'json'
require 'open3'

require 'leakferret/version'
require 'leakferret/error'
require 'leakferret/platform'
require 'leakferret/binary'
require 'leakferret/client'

# Ruby wrapper around the native `leakferret` secret scanner.
#
# leakferret finds hardcoded secrets, confirms which ones are actually live by
# calling the provider, and rewrites them to read from environment variables.
# This gem is a thin wrapper: the native binary (written in Rust) is downloaded
# once per platform on first use and cached, then each call shells out to it
# and parses the JSON it prints. The full secret value never leaves your
# machine; every finding carries only a redacted `first4...last4` preview.
#
# The three top-level methods mirror the CLI verbs and each return an array of
# finding hashes.
#
# @example Scan the working tree
#   Leakferret.scan(".").each do |f|
#     puts "#{f['path']}:#{f['line']} #{f['pattern']} [#{f['verdict']}]"
#   end
#
# @example Fail a script on any live secret
#   exit(1) unless Leakferret.verify(".", mode: "only-verified").empty?
#
# @see https://leakferret.com
# @see https://github.com/leakferrethq/leakferret
module Leakferret
  class << self
    # Scan a path for candidate secrets. This is the regex pre-filter only (no
    # classification, no verification): the fastest, fully offline pass.
    #
    # @param path [String] file or directory to scan, relative or absolute
    # @option opts [Array<String>] :exclude glob(s) to skip
    # @option opts [Array<String>, String] :only restrict the scan to these path(s)
    # @option opts [Boolean] :show_fixtures (false) include catalog fixtures in the result
    # @return [Array<Hash>] candidate findings, each with `path`, `line`,
    #   `pattern`, `verdict`, and `match_redacted` keys
    # @raise [BinaryInvocationError] if the binary exits with an unexpected status
    # @example
    #   Leakferret.scan("app/", exclude: ["**/*_test.rb"])
    def scan(path = '.', **opts)
      Client.new.scan(path, **opts)
    end

    # Scan, classify, and verify. Real findings are confirmed live with a
    # harmless API call to the provider (AWS, GitHub, Stripe, and others), so
    # this method makes outbound network requests.
    #
    # @param path [String] file or directory to scan
    # @option opts [String] :mode ("best-effort") verify mode: `none`,
    #   `best-effort`, `only-verified`, or `ever-verified`
    # @option opts [Integer] :timeout (10) per-verifier timeout in seconds
    # @option opts [Array<String>] :exclude glob(s) to skip
    # @option opts [Array<String>, String] :only restrict the scan to these path(s)
    # @return [Array<Hash>] findings with `verdict` and `verification` filled in
    # @raise [BinaryInvocationError] if the binary exits with an unexpected status
    # @example Only return secrets confirmed live
    #   Leakferret.verify(".", mode: "only-verified")
    def verify(path = '.', **opts)
      Client.new.verify(path, **opts)
    end

    # Scan, classify, and propose environment-variable rewrites for real
    # findings. Pass `apply: true` to write the rewrites to disk in place.
    #
    # @param path [String] file or directory to scan
    # @param apply [Boolean] when true, edit files in place; otherwise only
    #   propose the replacements
    # @option opts [String] :backend ("env") rewrite backend, e.g. `env`, `doppler`
    # @return [Array<Hash>] findings, each with a `replacement` proposal attached
    # @raise [BinaryInvocationError] if the binary exits with an unexpected status
    # @example Apply rewrites and seed Doppler
    #   Leakferret.rewrite(".", apply: true, backend: "doppler")
    def rewrite(path = '.', apply: false, **opts)
      Client.new.rewrite(path, apply: apply, **opts)
    end

    # Absolute path to the native binary, downloading it on first use.
    #
    # @return [String] absolute filesystem path to the `leakferret` executable
    # @raise [BinaryNotFoundError] if the binary is missing and cannot be fetched
    def binary_path
      Binary.path
    end

    # Version string reported by the bundled native binary. May differ from
    # {VERSION} (the gem's own version) during pre-release; see {BINARY_VERSION}.
    #
    # @return [String] the binary's `--version` output, stripped
    def binary_version
      out, _err, _status = Open3.capture3(binary_path, '--version')
      out.strip
    end
  end
end
