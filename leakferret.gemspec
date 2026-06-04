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
    them to read from environment variables instead.

    Precompiled platform gems bundle the native binary inside the gem, so a
    normal `gem install` ships the binary through RubyGems itself: no download,
    no network access, and no Rust toolchain. You can audit exactly what you are
    about to run with `gem unpack leakferret`. The plain `ruby`-platform gem
    fetches and checksum-verifies the binary on first use, for platforms without
    a prebuilt gem and for anyone who prefers to build it themselves.

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

  base_files = Dir.glob(%w[
    lib/**/*.rb
    exe/*
    README.md
    LICENSE.txt
    .yardopts
  ])

  # Two build modes, selected by the LEAKFERRET_GEM_PLATFORM env var:
  #
  #   unset -> source ("ruby") gem. No binary is bundled; the gem downloads and
  #            SHA256-verifies the binary on first use (ext/extconf.rb also
  #            pre-fetches it at install). This covers platforms without a
  #            prebuilt gem, and anyone who wants to audit or build the binary.
  #
  #   set   -> precompiled platform gem (e.g. x86_64-linux, arm64-darwin). The
  #            release tooling stages the platform binary into lib/leakferret/bin/
  #            and it ships INSIDE the gem. No download, no network, no extension
  #            hook. lib/leakferret/binary.rb resolves the bundled binary first.
  gem_platform = ENV.fetch('LEAKFERRET_GEM_PLATFORM', '').strip

  if gem_platform.empty?
    spec.files      = base_files + Dir.glob('ext/**/*.rb')
    spec.extensions = ['ext/leakferret/extconf.rb']
  else
    spec.platform = gem_platform
    bundled = Dir.glob('lib/leakferret/bin/*').reject { |f| File.directory?(f) }
    if bundled.empty?
      raise "LEAKFERRET_GEM_PLATFORM=#{gem_platform} but no binary is staged in " \
            'lib/leakferret/bin/. Stage the platform binary before building.'
    end

    spec.files = base_files + bundled
  end

  spec.bindir        = 'exe'
  spec.executables   = ['leakferret']
  spec.require_paths = ['lib']
end
