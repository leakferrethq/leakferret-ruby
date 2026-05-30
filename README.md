<p align="center">
  <img src="assets/logo.png" alt="leakferret" width="380">
</p>

# leakferret (Ruby gem)

> MCP-native secret scanner — verified findings, agent-applied rewrites.

Ruby gem wrapper around the native [`leakferret`](https://github.com/leakferrethq/leakferret)
binary. This gem ships no scanning logic of its own: it installs a tiny Ruby
shim plus a small executable, and downloads the prebuilt, statically-linked
binary (written in Rust) from GitHub Releases once per platform at install
time. All the work — scan, classify, verify, rewrite — happens in that single
binary.

This is the same packaging pattern used by `ruff`, `biome`, and `esbuild`:
distributing the toolchain to build a Rust engine on every machine is
unfriendly, so we ship the compiled engine instead.

## What leakferret does

leakferret finds hardcoded secrets and API keys in your code and helps you
remove them, in five stations:

1. **Scan** — regex pre-filter over files; respects `.gitignore` and also reads
   dotfiles like `.env`.
2. **Catalog** — a signed database of known-public example credentials (Stripe
   test keys, `AKIAIOSFODNN7EXAMPLE`, jwt.io samples) so documented examples are
   marked `FIXTURE` instead of false-alarming.
3. **Classify** — a `REAL` / `FIXTURE` / `UNKNOWN` verdict, from offline
   heuristics or by asking the host editor/agent language model (no extra API
   key, no cost).
4. **Verify** — a real but harmless API call to the provider (AWS SigV4,
   GitHub, GitLab, Stripe, OpenAI, Anthropic, Slack, Twilio, SendGrid, Mailgun,
   Datadog, Heroku, npm, PyPI, DigitalOcean) to confirm a key is live, plus a
   trufflehog fallback.
5. **Rewrite** — swap a hardcoded literal for an environment-variable lookup
   (`ENV.fetch` in Ruby, `process.env` in JS, `os.environ` in Python), add a
   `.env.example` line, and print secret-manager seed commands.

**Privacy invariant:** the full secret value never leaves your machine. Only a
redacted first-4-plus-last-4 preview (e.g. `AKIA...4XYZ`) is ever written to a
report, log, network message, or model prompt. Verification calls go straight
from your machine to the provider — leakferret has no servers.

## Install

```bash
gem install leakferret
```

This downloads `leakferret-{version}-{platform}.tar.gz` from GitHub Releases and
unpacks the binary into `lib/leakferret/bin/`.

Add it to a `Gemfile` for project-local use:

```ruby
gem 'leakferret'
```

Requires Ruby >= 3.1.

## CLI

The gem installs a `leakferret` executable that simply `exec`s the binary, so
every subcommand and flag works exactly as upstream:

```bash
leakferret scan .
leakferret verify . --only-verified
leakferret rewrite . --apply --backend doppler
leakferret baseline init
leakferret catalog info
leakferret mcp                 # MCP server on stdio
```

`leakferret scan --git` walks commit history. Output formats are `pretty`
(colored terminal), `json`, and `sarif` (for GitHub Code Scanning).

## Ruby API

```ruby
require 'leakferret'

# Regex pre-filter only.
findings = Leakferret.scan('.')

# + provider-verified (live HTTP to GitHub / Stripe / AWS / ...).
findings = Leakferret.verify('.', mode: 'only-verified')

# + propose rewrites for REAL findings.
findings = Leakferret.rewrite('.', backend: 'doppler')

# Apply rewrites in place.
Leakferret.rewrite('.', apply: true)
```

Each `Finding` is a hash with `path`, `line`, `column`, `pattern`, `severity`,
`verdict`, `match_redacted`, `confidence`, `verification`, and `fingerprint`.

## Using a local binary

Every leakferret wrapper honors the `LEAKFERRET_BIN` environment variable. Point
it at a binary on disk and the wrapper runs that instead of the downloaded copy:

```bash
export LEAKFERRET_BIN=/opt/leakferret/leakferret
leakferret scan .
```

For air-gapped or offline installs, set `LEAKFERRET_SKIP_DOWNLOAD=1` to skip the
release download and position the binary yourself.

## License

MIT for this gem and the bundled binary. The fixture catalog **data** is
CC-BY-SA-4.0 — see [`leakferret-catalog`](https://github.com/leakferrethq/leakferret-catalog).

---

Part of [leakferret](https://github.com/leakferrethq/leakferret) ·
[leakferret.com](https://leakferret.com) ·
maintained by Maria Khan &lt;missusk@protonmail.com&gt;.
