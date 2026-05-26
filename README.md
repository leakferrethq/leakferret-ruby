# leakferret (Ruby wrapper)

Ruby gem wrapper around the native [`leakferret`](https://github.com/leakferrethq/leakferret)
binary (written in Rust). Same `Findings` API as the pre-alpha 0.0.x
Ruby gem; the engine is the single statically-linked binary downloaded
once per platform at install time.

## Why a thin wrapper

Distributing pure Ruby gem-installing a Rust toolchain is unfriendly.
The pattern here matches `ruff` (Python), `biome` (npm), and `esbuild`
(npm): the gem ships a tiny Ruby shim, and `extconf.rb` downloads the
prebuilt binary from GitHub Releases.

## Install

```bash
gem install leakferret
```

This downloads `leakferret-{version}-{platform}.tar.gz` from
GitHub Releases and unpacks it into `lib/leakferret/bin/`.

Set `LEAKFERRET_SKIP_DOWNLOAD=1` if you want to position the binary
yourself (e.g. for air-gapped CI).

## API

```ruby
require 'leakferret'

# Regex pre-filter only.
findings = Leakferret.scan('.')

# + provider-verified (live HTTP to GitHub/Stripe/AWS/...).
findings = Leakferret.verify('.', mode: 'only-verified')

# + propose rewrites for REAL findings.
findings = Leakferret.rewrite('.', backend: 'doppler')

# Apply rewrites in place.
Leakferret.rewrite('.', apply: true)
```

Each `Finding` is a hash with `path`, `line`, `column`, `pattern`,
`severity`, `verdict`, `match_redacted`, `confidence`, `verification`,
`fingerprint`.

## CLI

The gem installs a `leakferret` executable that just `exec`s the
binary, so all subcommands and flags work identically:

```bash
leakferret scan .
leakferret verify . --only-verified
leakferret rewrite . --apply
leakferret mcp
leakferret baseline init
leakferret catalog info
```

## License

MIT.

The bundled binary is also MIT. The fixture catalog data shipped with
it is CC-BY-SA-4.0 — see `leakferret-catalog` for details.
