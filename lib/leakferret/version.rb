# frozen_string_literal: true

module Leakferret
  # The gem's own version (what `gem install leakferret` resolves).
  # @return [String]
  VERSION = '0.1.12'

  # The native binary release this gem downloads and runs. Tracks the
  # leakferret core release and can move independently of {VERSION}
  # (e.g. a gem-only bugfix keeps the same binary).
  # @return [String]
  BINARY_VERSION = '0.1.7'
end
