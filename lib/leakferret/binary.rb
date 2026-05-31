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
      require 'rubygems/package'

      FileUtils.mkdir_p(dest.dirname)
      # Stream download -> gunzip -> untar in pure Ruby (no external `tar`,
      # which on Windows mis-reads `C:\` as a remote host). The archive nests
      # everything under leakferret-<version>-<triple>/, so match by basename.
      found = false
      URI.open(download_url) do |io| # rubocop:disable Security/Open
        Zlib::GzipReader.wrap(io) do |gz|
          Gem::Package::TarReader.new(gz) do |tar|
            tar.each do |entry|
              next unless entry.file?
              next unless File.basename(entry.full_name) == Platform.binary_name

              File.binwrite(dest, entry.read)
              found = true
            end
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
