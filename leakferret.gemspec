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
    about to run with `gem unpack leakferret`. The gem never fetches and runs a
    binary off the internet - there is no download code to vet. On a platform
    without a prebuilt gem, the source gem tells you to build from source
    (`cargo install leakferret-cli`) or point LEAKFERRET_BIN at a binary.

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
    CHANGELOG.md
    .yardopts
  ])

  # Two build modes, selected by the LEAKFERRET_GEM_PLATFORM env var. Neither
  # downloads anything or ships an extension hook - the gem has no fetch-and-run
  # code at all.
  #
  #   unset -> source ("ruby") gem. Ships no binary. On a platform without a
  #            prebuilt gem, lib/leakferret/binary.rb raises with build-from-
  #            source / LEAKFERRET_BIN instructions. This is the graceful
  #            fallback so `bundle install` still resolves on, say, Alpine or
  #            aarch64-linux.
  #
  #   set   -> precompiled platform gem (e.g. x86_64-linux, arm64-darwin). The
  #            release tooling stages the platform binary into lib/leakferret/bin/
  #            and it ships INSIDE the gem; binary.rb resolves it directly.
  gem_platform = ENV.fetch('LEAKFERRET_GEM_PLATFORM', '').strip

  if gem_platform.empty?
    spec.files = base_files
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
