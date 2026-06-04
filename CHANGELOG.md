# Changelog

All notable changes to the `leakferret` gem are documented here. The gem version
can move independently of the native binary version it targets.

## [0.1.15] - 2026-06-04

### Changed
- Ship **precompiled platform gems** (x86_64-linux, x86_64-darwin, arm64-darwin,
  x64-mingw-ucrt) with the native binary bundled inside the gem. A normal
  `gem install` gets the binary through RubyGems itself: no download, no
  network, no Rust toolchain. Audit it with `gem unpack leakferret`. Mirrors how
  `nokogiri` and `sorbet-static` ship.
- **Removed the binary-download flow entirely.** Dropped the install-time
  `extconf.rb` pre-fetch and the runtime download + SHA256 logic. The gem now
  has no fetch-and-run code to audit at all.
- On a platform without a prebuilt binary (e.g. aarch64-linux, Alpine/musl), the
  source gem still installs (so `bundle install` resolves) and raises a clear
  message pointing to `cargo install leakferret-cli` or `LEAKFERRET_BIN`. It
  never downloads.
- Released gems now carry GitHub build provenance (SLSA attestation).

### Removed
- `ext/leakferret/extconf.rb` and the runtime binary downloader.

Targets the leakferret `0.1.9` binary (unchanged).
