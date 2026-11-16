# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "rubocop/rake_task"

# The contract and sandbox suites live in subdirectories, so a plain
# `rake test` needs neither Node nor credentials.
Minitest::TestTask.create(:test) do |t|
  t.test_globs = ["test/*_test.rb"]
end

namespace :test do
  Minitest::TestTask.create(:contract) do |t|
    t.test_globs = ["test/contract/**/*_test.rb"]
  end
  Rake::Task["test:contract"].clear_comments.add_description "Run the client against a Prism mock of the spec"

  Minitest::TestTask.create(:sandbox) do |t|
    t.test_globs = ["test/sandbox/**/*_test.rb"]
  end
  Rake::Task["test:sandbox"].clear_comments.add_description "Smoke-test the real Sandbox (needs credentials)"
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

desc "Build the API reference into doc/; fails on any YARD warning or undocumented public API"
task docs: "docs:coverage" do
  sh "yard", "doc", "--fail-on-warning"
end

namespace :docs do
  desc "Fail if a public class, module, method, attribute or constant has no doc comment"
  task :coverage do
    require "yard"
    stats = YARD::CLI::Stats.new
    stats.run("--no-save", "--fail-on-warning")
    # A generated enum module's constants are its known values; each one's
    # name and value are its documentation.
    public_api = stats.all_objects.select { |object| %i[module class constant method].include?(object.type) }
    undocumented = public_api.select { |object| object.docstring.blank? }.reject do |object|
      object.type == :constant && object.file.start_with?("lib/teachmehipaa/models/")
    end
    abort "Undocumented public API:\n  #{undocumented.map(&:path).sort.join("\n  ")}" if undocumented.any?
  end
end

task default: %i[rubocop rbs:validate rbs:test]
