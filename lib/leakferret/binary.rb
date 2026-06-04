# frozen_string_literal: true

require 'pathname'

require_relative 'version'
require_relative 'platform'
require_relative 'error'

module Leakferret
  # Resolves the native `leakferret` binary that ships inside the gem.
  #
  # Precompiled platform gems bundle the binary at lib/leakferret/bin/. There is
  # deliberately no download path: the gem either carries the binary for your
  # platform or it tells you how to provide one. Nothing here touches the
  # network, so what you `gem unpack` is exactly what runs - the whole gem is
  # auditable, with no fetch-and-execute code to vet.
  #
  # @api private
  module Binary
    # Where a precompiled platform gem stages the native binary.
    BUNDLED_DIR = Pathname.new(__dir__).join('bin').freeze

    module_function

    # Absolute path to the native binary. Resolution order:
    #   1. LEAKFERRET_BIN             - explicit override
    #   2. lib/leakferret/bin/<name>  - bundled by the precompiled platform gem
    #
    # @return [String] absolute path to the executable
    # @raise [BinaryNotFoundError] if the override is missing, or no binary is
    #   bundled for this platform
    def path
      override = ENV['LEAKFERRET_BIN']
      unless override.nil? || override.empty?
        unless File.file?(override)
          raise BinaryNotFoundError, "LEAKFERRET_BIN points to a missing file: #{override}"
        end

        return override
      end

      bundled = BUNDLED_DIR.join(Platform.binary_name)
      if bundled.file?
        # Make sure it is executable in case the mode did not survive packaging
        # or install; the gem dir is usually writable, a read-only one is
        # harmless to skip.
        unless Platform.windows? || bundled.executable?
          begin
            bundled.chmod(0o755)
          rescue StandardError
            # best effort
          end
        end
        return bundled.to_s
      end

      raise BinaryNotFoundError, no_binary_message
    end

    # Message shown when the source/fallback gem is installed on a platform with
    # no precompiled binary. No automatic download is attempted - the user
    # provides the binary, or builds it.
    #
    # @return [String] multi-line build-from-source instructions
    def no_binary_message
      plat =
        begin
          Gem::Platform.local.to_s
        rescue StandardError
          RUBY_PLATFORM
        end

      <<~MSG
        No prebuilt leakferret binary ships for this platform (#{plat}).

        leakferret publishes precompiled gems for x86_64 and arm64 macOS,
        x86_64 Linux (glibc), and x86_64 Windows. On any other platform, provide
        the binary yourself - either of these works:

          1. Build from source and point LEAKFERRET_BIN at it:
               cargo install leakferret-cli
               export LEAKFERRET_BIN="$(command -v leakferret)"

          2. Download a release binary for your platform from
               https://github.com/leakferrethq/leakferret/releases
             and set LEAKFERRET_BIN to its absolute path.
      MSG
    end
  end
end
