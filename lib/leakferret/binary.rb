# frozen_string_literal: true

require 'pathname'

require_relative 'version'
require_relative 'platform'
require_relative 'error'

module Leakferret
  # Resolves (and, if needed, downloads) the native `leakferret` binary.
  #
  # The binary is fetched into an absolute, user-writable cache directory
  # rather than into the gem's own tree. RubyGems builds extensions in a
  # throwaway temp dir, so anything written relative to the gem during
  # `gem install` is discarded — the cache path sidesteps that entirely and
  # also lets a plain `gem install` (no extension) work.
  module Binary
    # A binary vendored inside the gem, if one was shipped (normally empty).
    BUNDLED_DIR = Pathname.new(__dir__).join('bin').freeze

    # SHA256 of each release tarball, pinned to BINARY_VERSION. The download is
    # verified against these before the archive is ever unpacked, so a tampered
    # or corrupted release asset is rejected instead of being executed. Because
    # the digests live in the gem source, auditing the published gem tells you
    # exactly which binary bytes it will run. Regenerate on every binary bump
    # from the release's `*.tar.gz.sha256` files.
    CHECKSUMS = {
      'aarch64-apple-darwin'     => '4db78de31252e8a2964528c817f12c73d46b660f453398c9c2f0feba6b370772',
      'aarch64-pc-windows-msvc'  => '021dce80072ae4cd553a23b05cddc9a878226668c92570df1b80c3221e034493',
      'x86_64-apple-darwin'      => 'b37747b336a3a18875b05a5c6e9aa736f53518fbcf8e722993f434cea41e0aa2',
      'x86_64-pc-windows-msvc'   => 'b0e32599f9d04e391d4b2d703e648c0a64739b15317434b0625eb00686cc6bb1',
      'x86_64-unknown-linux-gnu' => '05420ee2cd7e1d617f96caf098fda4a260ba361bc70af7e47da004959986cbbd'
    }.freeze

    module_function

    # Absolute path to the native binary, downloading it on first use if
    # necessary. Resolution order:
    #   1. LEAKFERRET_BIN          — explicit override
    #   2. lib/leakferret/bin/     — a binary vendored in the gem
    #   3. the per-version cache   — fetched on a prior run or at install
    #   4. download into the cache now
    def path
      override = ENV['LEAKFERRET_BIN']
      unless override.nil? || override.empty?
        unless File.file?(override)
          raise BinaryNotFoundError, "LEAKFERRET_BIN points to a missing file: #{override}"
        end

        return override
      end

      bundled = BUNDLED_DIR.join(Platform.binary_name)
      return bundled.to_s if bundled.file?

      return cache_path.to_s if cache_path.file?

      ensure!
      raise BinaryNotFoundError, install_instructions(cache_path) unless cache_path.file?

      cache_path.to_s
    end

    # User-writable cache directory, namespaced by the binary version so a
    # gem upgrade fetches a fresh binary instead of reusing a stale one.
    def cache_dir
      base =
        if Platform.windows?
          ENV['LOCALAPPDATA'] || File.join(Dir.home, 'AppData', 'Local')
        else
          ENV['XDG_CACHE_HOME'] || File.join(Dir.home, '.cache')
        end
      Pathname.new(base).join('leakferret', BINARY_VERSION)
    end

    def cache_path
      cache_dir.join(Platform.binary_name)
    end

    def download_url
      'https://github.com/leakferrethq/leakferret/releases/download/' \
        "v#{BINARY_VERSION}/leakferret-#{BINARY_VERSION}-#{Platform.triple}.tar.gz"
    end

    # Download and unpack the binary into the cache. Idempotent: a no-op when
    # the binary is already cached. Returns the path; raises on failure.
    def ensure!
      dest = cache_path
      return dest.to_s if dest.file?

      require 'fileutils'
      require 'open-uri'
      require 'zlib'
      require 'digest'
      require 'stringio'
      require 'rubygems/package'

      expected = CHECKSUMS[Platform.triple]
      if expected.nil?
        raise BinaryNotFoundError,
              "no pinned checksum for platform #{Platform.triple}; refusing to run an " \
              'unverified binary. Build from source and set LEAKFERRET_BIN instead.'
      end

      FileUtils.mkdir_p(dest.dirname)

      # Download the whole tarball, verify its SHA256 against the pinned value,
      # and only then unpack. Nothing is written to the cache (let alone marked
      # executable) until the bytes match, so a tampered or truncated release
      # asset is rejected rather than run.
      tarball = URI.open(download_url, &:read) # rubocop:disable Security/Open
      actual = Digest::SHA256.hexdigest(tarball)
      unless actual.casecmp?(expected)
        raise BinaryNotFoundError,
              "checksum mismatch for #{download_url}\n" \
              "  expected #{expected}\n  got      #{actual}\n" \
              'Refusing to install a binary that does not match the pinned hash.'
      end

      # Unpack in pure Ruby (no external `tar`, which on Windows mis-reads `C:\`
      # as a remote host). The archive nests everything under
      # leakferret-<version>-<triple>/, so match by basename.
      found = false
      Zlib::GzipReader.wrap(StringIO.new(tarball)) do |gz|
        Gem::Package::TarReader.new(gz) do |tar|
          tar.each do |entry|
            next unless entry.file?
            next unless File.basename(entry.full_name) == Platform.binary_name

            File.binwrite(dest, entry.read)
            found = true
          end
        end
      end
      raise BinaryNotFoundError, "binary not found inside #{download_url}" unless found

      FileUtils.chmod(0o755, dest) unless Platform.windows?
      dest.to_s
    end

    def install_instructions(candidate)
      <<~MSG
        leakferret native binary not found, and the automatic download failed.

        Expected it at:
          #{candidate}

        Download the binary for your platform from:
          https://github.com/leakferrethq/leakferret/releases

        then either place it at the path above or point LEAKFERRET_BIN at it.
      MSG
    end
  end
end
