# frozen_string_literal: true

require 'json'
require 'open3'

require 'leakferret/version'
require 'leakferret/error'
require 'leakferret/platform'
require 'leakferret/binary'
require 'leakferret/client'

# Ruby wrapper around the native `leakferret` binary.
#
# The binary is downloaded once per platform at gem install time
# (`ext/leakferret/extconf.rb`) into `lib/leakferret/bin/`. Subsequent
# calls shell out to it and parse the JSON output.
module Leakferret
  class << self
    # Scan a directory; returns an array of finding hashes.
    def scan(path = '.', **opts)
      Client.new.scan(path, **opts)
    end

    # Scan + verify + classify; returns findings with verification +
    # verdict filled in.
    def verify(path = '.', **opts)
      Client.new.verify(path, **opts)
    end

    # Scan + classify + propose rewrites for REAL findings. Use
    # apply: true to write the rewrites in place.
    def rewrite(path = '.', apply: false, **opts)
      Client.new.rewrite(path, apply: apply, **opts)
    end

    # Path to the bundled binary. Useful for tooling integration.
    def binary_path
      Binary.path
    end

    # Version reported by the bundled binary (Rust) — may differ from
    # the gem version during pre-release.
    def binary_version
      out, _err, _status = Open3.capture3(binary_path, '--version')
      out.strip
    end
  end
end
