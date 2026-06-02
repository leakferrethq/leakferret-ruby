require_relative 'lib/leakferret/version'

Gem::Specification.new do |spec|
  spec.name        = 'leakferret'
  spec.version     = Leakferret::VERSION
  spec.authors     = ['Maria Khan']
  spec.email       = ['missusk@protonmail.com']

  spec.summary     = 'Context-aware secret detection (Ruby wrapper for the leakferret binary).'
  spec.description = <<~DESC
    Context-aware secret scanning for Ruby projects. A thin wrapper around the
    native leakferret binary (written in Rust): it finds hardcoded secrets,
    confirms which ones are actually live by calling the provider, and rewrites
    them to read from environment variables instead. The platform binary is
    downloaded automatically on first use, so no Rust toolchain is required.

    The API exposes Leakferret.scan, Leakferret.verify, and Leakferret.rewrite
    (each returning Finding objects), plus a `leakferret` command-line tool.
  DESC
  spec.homepage    = 'https://github.com/leakferrethq/leakferret-ruby'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = spec.homepage
  spec.metadata['changelog_uri']     = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/leakferret'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob(%w[
    lib/**/*.rb
    ext/**/*.rb
    exe/*
    README.md
    LICENSE.txt
    .yardopts
  ])
  spec.bindir      = 'exe'
  spec.executables = ['leakferret']
  spec.require_paths = ['lib']

  # ext/extconf.rb best-effort pre-fetches the platform binary into a
  # user cache at install time; lib/leakferret/binary.rb also fetches it
  # lazily on first use, so the gem works even if the pre-fetch is skipped.
  spec.extensions = ['ext/leakferret/extconf.rb']
end
