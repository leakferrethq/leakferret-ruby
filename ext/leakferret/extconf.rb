# frozen_string_literal: true

# Post-install: download the right native binary for this platform and
# unpack it into lib/leakferret/bin/. Skipped if LEAKFERRET_SKIP_DOWNLOAD
# is set (useful for users vendoring the binary themselves, or for CI
# that pre-positions it).
#
# We deliberately do NOT compile the Rust source here. Compiling Rust
# at gem-install time would force every user to have a Rust toolchain
# AND wait for a 90s build. The download-binary model matches what
# `ruff` (Python), `biome` (npm), and `esbuild` (npm) do.

require 'fileutils'
require 'open-uri'
require 'pathname'
require 'rbconfig'
require 'digest'

require_relative '../../lib/leakferret/version'
require_relative '../../lib/leakferret/platform'

VERSION = Leakferret::VERSION
TRIPLE  = Leakferret::Platform.triple
BIN     = Leakferret::Platform.binary_name
BIN_DIR = Pathname.new(__dir__).join('..', '..', 'lib', 'leakferret', 'bin').expand_path
URL     = "https://github.com/leakferrethq/leakferret/releases/download/v#{VERSION}/" \
          "leakferret-#{VERSION}-#{TRIPLE}.tar.gz"

# Emit an empty Makefile so rubygems considers the extension built.
File.write('Makefile', "all:\n\t@true\ninstall:\n\t@true\nclean:\n\t@true\n")

def log(msg)
  warn "[leakferret/extconf] #{msg}"
end

if ENV['LEAKFERRET_SKIP_DOWNLOAD']
  log 'LEAKFERRET_SKIP_DOWNLOAD set; skipping binary download.'
  exit 0
end

FileUtils.mkdir_p(BIN_DIR)
dest = BIN_DIR.join(BIN)
if dest.file?
  log "binary already present at #{dest}; skipping download."
  exit 0
end

log "downloading #{URL}"
begin
  tar_path = Pathname.new(Dir.tmpdir).join("leakferret-#{VERSION}-#{TRIPLE}.tar.gz")
  URI.open(URL) { |io| File.binwrite(tar_path, io.read) }
  system('tar', '-xzf', tar_path.to_s, '-C', BIN_DIR.to_s) ||
    abort("tar extraction failed for #{tar_path}")
  FileUtils.chmod(0o755, dest) unless Leakferret::Platform.windows?
  log "installed binary at #{dest}"
rescue StandardError => e
  log "binary download failed: #{e.class}: #{e.message}"
  log 'gem still installed; set LEAKFERRET_SKIP_DOWNLOAD=1 to suppress this download attempt and supply the binary yourself.'
  # Exit 0 so the install doesn't fail entirely — the user will get a
  # clear error from Binary.path the first time they invoke the API.
  exit 0
end
