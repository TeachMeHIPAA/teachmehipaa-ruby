# frozen_string_literal: true

# Regenerates the resource and model layer from the vendored IR:
# `bundle exec rake generate`.
require "fileutils"
require_relative "generator"

puts SdkGenerator.write(File.expand_path("..", __dir__))
