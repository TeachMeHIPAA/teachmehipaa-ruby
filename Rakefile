# frozen_string_literal: true

require "minitest/test_task"
require "rubocop/rake_task"

Minitest::TestTask.create(:test) do |t|
  t.test_globs = ["test/**/*_test.rb"]
end

RuboCop::RakeTask.new(:rubocop)

desc "Regenerate the models and resources (and their signatures) from openapi/sdk-ir.json"
task :generate do
  ruby "scripts/generate.rb"
end

namespace :rbs do
  desc "Validate the RBS signatures in sig/"
  task :validate do
    sh "rbs", "-I", "sig", "validate"
  end

  desc "Run the tests with every call into the library checked against sig/"
  task :test do
    env = {
      "RBS_TEST_TARGET" => "TeachMeHipaa::*",
      "RBS_TEST_OPT" => "-I sig -r json -r uri -r time",
      "RBS_TEST_LOGLEVEL" => "error",
      "RUBYOPT" => "#{ENV.fetch("RUBYOPT", "")} -rrbs/test/setup",
    }
    sh env, FileUtils::RUBY, "-S", "rake", "test"
  end
end

task default: %i[rubocop rbs:validate rbs:test]
