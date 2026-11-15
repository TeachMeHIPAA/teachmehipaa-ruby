# frozen_string_literal: true

require_relative "lib/teachmehipaa/version"

Gem::Specification.new do |spec|
  spec.name = "teachmehipaa"
  spec.version = TeachMeHipaa::VERSION
  spec.authors = ["TeachMeHIPAA"]
  spec.summary = "Ruby library for the TeachMeHIPAA Developer API"
  spec.description = "Enroll Learners in HIPAA training and track compliance from your own systems."
  spec.homepage = "https://github.com/TeachMeHIPAA/teachmehipaa-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "rubygems_mfa_required" => "true",
  }

  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]
end
