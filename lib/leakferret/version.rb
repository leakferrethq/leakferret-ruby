# frozen_string_literal: true

module Leakferret
  # The gem's own version.
  VERSION = '0.1.5'

  # The native binary release this gem downloads. Tracks the leakferret
  # core release, which may move independently of the gem's own version
  # (e.g. a gem-only bugfix).
  BINARY_VERSION = '0.1.3'
end
