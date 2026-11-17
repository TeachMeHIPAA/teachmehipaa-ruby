# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/sample_transport"
require_relative "support/doc_samples"
require "stringio"

# Keeps the README honest. Every fenced ruby block must follow a
# "<!-- sample: id -->" line (see DocSamples). Every sample must compile, and
# each one either runs here against FakeTransport, with a check of what it
# printed and sent, or is listed in SYNTAX_ONLY with the reason it can't run.
class ReadmeTest < Minitest::Test
  include ClientHelpers

  SYNTAX_ONLY = { "install" => "a Gemfile" }.freeze
  LEARNERS_PATH = "/organizations/#{ORG_ID}/learners".freeze
  ENVIRONMENT = { "TMH_CLIENT_ID" => CLIENT_ID, "TMH_CLIENT_SECRET" => CLIENT_SECRET }.freeze

  def self.samples = DocSamples.all

  def self.run_checks = @run_checks ||= []

  # Defines a test that runs sample +id+; registering it is what lets the
  # completeness test pass.
  def self.runs(id, behaviour, &)
    run_checks << id
    define_method("test_sample_#{id.tr("/-", "__")}_#{behaviour}", &)
  end

  # What a sample runs as: +puts+ is recorded.
  class SampleContext
    attr_reader :output

    def initialize
      @output = []
    end

    def puts(*values)
      values = [""] if values.empty?
      values.flatten.each { |value| @output << value.to_s }
      nil
    end
  end

  def test_every_ruby_block_is_a_tagged_sample
    untagged = self.class.samples.select { |sample| sample.id.nil? }.map { |sample| "#{sample.file}:#{sample.line}" }

    assert_empty untagged, "these ruby blocks need a <!-- sample: id --> line"
    ids = self.class.samples.map(&:id)

    assert_equal ids.uniq, ids, "sample ids must be unique within a document"
  end

  def test_every_sample_compiles
    self.class.samples.each do |sample|
      RubyVM::InstructionSequence.compile(sample.code, sample.file, sample.file, sample.line)
    rescue SyntaxError => e
      flunk "sample #{sample.id} does not compile: #{e.message}"
    end
  end

  def test_every_sample_is_run_or_named_as_syntax_only
    expected = self.class.samples.filter_map(&:id).sort

    assert_equal expected, (self.class.run_checks.uniq + SYNTAX_ONLY.keys).sort
  end

  runs "quickstart", "lists_every_page_of_learners" do
    fake = sandbox_api
    fake.on("GET", LEARNERS_PATH, learner_pages)

    output = run_sample("quickstart", fake)

    assert_equal ["ana@example.com", "ben@example.com", "cy@example.com"], output
    first, second = fake.requests_to("GET", LEARNERS_PATH).map { |request| query(request) }

    assert_equal({ "status" => "in_progress" }, first)
    assert_equal({ "status" => "in_progress", "cursor" => "c2" }, second)
    assert sandbox?(fake.requests.first)
  end

  private

  # Runs sample +id+ with every client pointed at +fake+ and the docs'
  # environment variables set, and returns what it printed.
  def run_sample(id, fake, context: SampleContext.new, stdout: StringIO.new)
    sample = DocSamples.find(id) or flunk "no sample #{id}"
    saved_env = ENVIRONMENT.keys.to_h { |name| [name, ENV.fetch(name, nil)] }
    saved_stdout = $stdout
    begin
      ENV.update(ENVIRONMENT)
      $stdout = stdout
      SampleTransport.using(fake) { context.instance_eval(sample.code, sample.file, sample.line) }
    ensure
      $stdout = saved_stdout
      ENV.update(saved_env)
    end
    context.output
  end

  def sandbox_api
    FakeTransport.new(SANDBOX_BASE)
                 .on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
                 .on("GET", "/auth/introspection", FakeTransport::Reply.json(introspection_json))
  end

  def sandbox?(request)
    request.url.start_with?(SANDBOX_BASE)
  end

  def query(request)
    URI.decode_www_form(URI(request.url).query.to_s).to_h
  end

  # Two pages of Learners, picked by the cursor each request carries.
  def learner_pages
    first = { "items" => [LEARNER_JSON, LEARNER_JSON.merge("learnerId" => "sub_ben", "email" => "ben@example.com")],
              "nextCursor" => "c2" }
    second = { "items" => [LEARNER_JSON.merge("learnerId" => "sub_cy", "email" => "cy@example.com")],
               "nextCursor" => nil }
    lambda do |request|
      FakeTransport::Reply.json(query(request)["cursor"] == "c2" ? second : first)
    end
  end
end
