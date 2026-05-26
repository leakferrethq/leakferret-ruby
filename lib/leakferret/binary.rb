# frozen_string_literal: true

require 'pathname'

module Leakferret
  module Binary
    BIN_DIR = Pathname.new(__dir__).join('bin').freeze

    module_function

    # Absolute path to the bundled binary. Raises if missing (i.e.
    # extconf.rb didn't run, or the user installed from source without
    # the download step).
    def path
      candidate = BIN_DIR.join(Platform.binary_name)
      raise BinaryNotFoundError, install_instructions(candidate) unless candidate.file?

      candidate.to_s
    end

    def install_instructions(candidate)
      <<~MSG
        leakferret native binary not found at:
          #{candidate}

        Try re-installing the gem so the extconf.rb post-install step
        runs:

          gem uninstall leakferret && gem install leakferret

        Or download the binary for your platform manually from:

          https://github.com/leakferrethq/leakferret/releases

        and place it at the path above.
      MSG
    end
  end
end
