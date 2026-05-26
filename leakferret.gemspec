require_relative 'lib/leakferret/version'

Gem::Specification.new do |spec|
  spec.name        = 'leakferret'
  spec.version     = Leakferret::VERSION
  spec.authors     = ['Maria Khan']
  spec.email       = ['missusk@protonmail.com']

  spec.summary     = 'Context-aware secret detection (Ruby wrapper for the leakferret binary).'
  spec.description = <<~DESC
    Ruby wrapper around the native `leakferret` binary (written in Rust).
    Same Findings API as the pre-alpha 0.0.x Ruby gem, but the heavy lifting
    runs in a single statically-linked binary downloaded on install.

    Provides:
      - Leakferret.scan(path)    -> [Finding, ...]
      - Leakferret.verify(path)  -> [Finding, ...]  (provider-verified)
      - Leakferret.rewrite(path) -> [Finding, ...]  (with .replacement filled)
      - `leakferret` executable that just exec's the binary.
  DESC
  spec.homepage    = 'https://github.com/leakferrethq/leakferret-ruby'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob(%w[
    lib/**/*.rb
    ext/**/*.rb
    exe/*
    README.md
    LICENSE.txt
  ])
  spec.bindir      = 'exe'
  spec.executables = ['leakferret']
  spec.require_paths = ['lib']

  # The ext/ extconf.rb downloads the right platform binary at install time
  # and unpacks it into `lib/leakferret/bin/`.
  spec.extensions = ['ext/leakferret/extconf.rb']
end
