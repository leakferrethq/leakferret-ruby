# frozen_string_literal: true

# Best-effort install-time pre-fetch of the native binary into the
# user-writable cache (see lib/leakferret/binary.rb). This is purely an
# optimisation so the first invocation is instant — the binary is also
# downloaded lazily on first use, so a failure here is harmless. Set
# LEAKFERRET_SKIP_DOWNLOAD to skip the pre-fetch.
#
# We deliberately do NOT compile the Rust source: that would force every
# user to have a Rust toolchain and wait for a long build. The
# download-binary model matches ruff (Python), biome/esbuild (npm).

require_relative '../../lib/leakferret/version'
require_relative '../../lib/leakferret/platform'
require_relative '../../lib/leakferret/error'
require_relative '../../lib/leakferret/binary'

# Emit an empty Makefile so rubygems considers the "extension" built.
File.write('Makefile', "all:\n\t@true\ninstall:\n\t@true\nclean:\n\t@true\n")

def log(msg)
  warn "[leakferret/extconf] #{msg}"
end

if ENV['LEAKFERRET_SKIP_DOWNLOAD']
  log 'LEAKFERRET_SKIP_DOWNLOAD set; binary will be downloaded on first use.'
  exit 0
end

begin
  path = Leakferret::Binary.ensure!
  log "binary ready at #{path}"
rescue StandardError => e
  log "pre-fetch failed (#{e.class}: #{e.message}); it will download on first use."
end

# Always succeed: a failed pre-fetch must not fail the gem install.
exit 0
