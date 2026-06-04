# Changelog

All notable changes to the `leakferret` gem are documented here. The gem version
can move independently of the native binary version it targets.

## [0.1.15] - 2026-06-04

### Changed
- Ship **precompiled platform gems** (x86_64-linux, x86_64-darwin, arm64-darwin,
  x64-mingw-ucrt) with the native binary bundled inside the gem. A normal
  `gem install` now gets the binary through RubyGems itself: no install-time or
  first-run download, no network, no Rust toolchain. Audit it with
  `gem unpack leakferret`. Mirrors how `nokogiri` and `sorbet-static` ship.
- The plain `ruby`-platform gem remains as a source/fallback for platforms
  without a prebuilt binary (e.g. aarch64-linux); it downloads and
  SHA256-verifies the binary on first use, as before.
- Released gems now carry GitHub build provenance (SLSA attestation).

Targets the leakferret `0.1.9` binary (unchanged).
