# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/sample_transport"
require_relative "../scripts/generator"
require "stringio"
require "tmpdir"

# Keeps docs/reference/code-samples.json, the Ruby samples the API reference
# shows, honest. Every IR operationId has a sample, every sample compiles,
# and each one runs through the real client against FakeTransport: it must
# send exactly one request to its own operation's method and path, finish
# without raising, and print or save something. A sample that names a
# method or keyword the library lacks fails here.
class CodeSamplesTest < Minitest::Test
  include ClientHelpers

  ROOT = File.expand_path("..", __dir__)
  DOCUMENT = JSON.parse(File.read(File.join(ROOT, SdkGenerator::CodeSamples::PATH), encoding: "UTF-8"))
  IR = JSON.parse(File.read(File.join(ROOT, "openapi/sdk-ir.json"), encoding: "UTF-8"))
  ENVIRONMENT = { "TMH_CLIENT_ID" => CLIENT_ID, "TMH_CLIENT_SECRET" => CLIENT_SECRET }.freeze
  OPERATION_NAME = "organizations/#{ORG_ID}/operations/op_01JD8T4V6W8X0Y2Z4A6B8C0D2E".freeze
  CSV = "email,status\r\ndana.whitfield@example.com,certified\r\n"
  PDF = "%PDF-1.7\ncertificate\n%%EOF".b.freeze

  # One body every JSON operation can read: models keep the fields they
  # don't declare, so a superset of every field a sample prints serves them
  # all. +type+ and +eventType+ pick a known member of the audit-event and
  # Event unions.
  RECORD = {
    "learnerId" => SdkGenerator::SampleCalls::LEARNER_ID, "email" => "dana.whitfield@example.com",
    "name" => "Dana Whitfield", "status" => "in_progress", "created" => true, "url" => "https://tme.so/l/x",
    "enrollmentId" => SdkGenerator::SampleCalls::ENROLLMENT_ID, "effectiveStatus" => "active", "cycle" => 2,
    "action" => "remind", "title" => "HIPAA Essentials", "expiresAt" => "2027-11-10T15:00:00Z",
    "shortLink" => "https://tme.so/a7Kq2Z", "compliantRate" => 0.92, "available" => 3, "total" => 10,
    "role" => "admin", "enabled" => false, "endpointUrl" => SdkGenerator::SampleCalls::WEBHOOK_URL,
    "secret" => "whsec_code-samples", "scopes" => %w[learners:read], "at" => "2026-11-15T12:00:00Z",
    "type" => "certificate.issued", "eventId" => "evt_01JD8C", "eventType" => "learner.certified",
    "occurredAt" => "2026-11-15T12:00:00Z", "data" => {},
    "results" => [{ "enrollmentId" => SdkGenerator::SampleCalls::ENROLLMENT_ID, "outcome" => "ok" }]
  }.freeze
  # A done Operation whose response serves both an export (export_result)
  # and a webhook Delivery (the WebhookDelivery union's +_tag+).
  OPERATION = {
    "name" => OPERATION_NAME, "done" => true,
    "response" => { "_tag" => "sent", "responseStatus" => 200, "format" => "csv", "contentType" => "text/csv",
                    "filename" => "export.csv", "rowCount" => 1, "dataBase64" => [CSV].pack("m0") }
  }.freeze

  def test_names_the_language_and_the_release
    assert_equal "ruby", DOCUMENT.fetch("language")
    assert_equal File.read(File.join(ROOT, "OPENAPI_VERSION")).strip, DOCUMENT.fetch("release")
  end

  def test_has_one_sample_per_ir_operation
    assert_equal operations.keys.sort, DOCUMENT.fetch("samples").keys.sort
    assert_equal 43, DOCUMENT.fetch("samples").length
  end

  def test_every_sample_compiles
    DOCUMENT.fetch("samples").each do |operation_id, source|
      RubyVM::InstructionSequence.compile(source, operation_id)
    rescue SyntaxError => e
      flunk "#{operation_id} does not compile: #{e.message}"
    end
  end

  def test_every_sample_uses_the_shared_example_values
    samples = DOCUMENT.fetch("samples")

    assert(samples.values.all? { |source| source.start_with?(%(require "teachmehipaa"\n)) })
    assert_includes samples.fetch("createLearner"), %(email: "dana.whitfield@example.com")
    assert_includes samples.fetch("importEnrollments"), %(file: "roster.csv")
    assert_includes samples.fetch("getCertificateVerification"), "TeachMeHipaa::Client.new(environment: :sandbox)"
  end

  def test_the_generator_refuses_an_operation_without_a_sample
    calls = SdkGenerator::SampleCalls::CALLS.except("getLearner")
    generator = SdkGenerator::CodeSamples.new(SdkGenerator::Ir.new(IR), calls:)

    assert_raises(ArgumentError) { generator.samples }
  end

  def test_the_generator_refuses_a_keyword_the_method_does_not_take
    calls = SdkGenerator::SampleCalls::CALLS.merge(
      "getLearner" => SdkGenerator::SampleCalls.call("learner", "puts learner.name", args: { learner_name: "x" }),
    )
    generator = SdkGenerator::CodeSamples.new(SdkGenerator::Ir.new(IR), calls:)
    error = assert_raises(ArgumentError) { generator.samples }

    assert_includes error.message, "learner_name"
  end

  IR.fetch("resources").flat_map { |resource| resource.fetch("methods") }.uniq { |m| m.fetch("operationId") }
    .each do |method|
      operation_id = method.fetch("operationId")
      define_method("test_#{SdkGenerator::Naming.snake(operation_id)}_sample_calls_its_operation") do
        check_sample(operation_id, method)
      end
    end

  private

  def operations
    IR.fetch("resources").flat_map { |resource| resource.fetch("methods") }.to_h do |method|
      [method.fetch("operationId"), method]
    end
  end

  def check_sample(operation_id, method)
    verb, path = route(method)
    fake = sandbox_api.on(verb, path, reply(method))
    # The update samples read the object first, for its ETag.
    fake.on("GET", path, FakeTransport::Reply.json(RECORD, headers: { "etag" => ETAG })) if verb == "PATCH"
    output, files = run_sample(DOCUMENT.fetch("samples").fetch(operation_id), fake)

    assert_equal 1, fake.requests_to(verb, path).length, "#{operation_id} must call #{verb} #{path} once"
    produced = output.reject(&:empty?) + files

    refute_empty produced, "#{operation_id} printed and saved nothing"
  end

  # The operation's HTTP method and path, with the samples' example ids.
  def route(method)
    template = method.dig("path", "template").gsub("{orgId}", ORG_ID).gsub(/\{(\w+)\}/) do
      SdkGenerator::SampleCalls::PATH_VALUES.fetch(Regexp.last_match(1))
    end
    verb = method.dig("path", "customVerb")
    [method.fetch("httpMethod"), verb ? "#{template}:#{verb}" : template]
  end

  def reply(method)
    case method.dig("response", "kind")
    when "binary" then FakeTransport::Reply.new(status: 200, body: PDF, content_type: "application/pdf", headers: {})
    when "empty" then FakeTransport::Reply.empty
    when "operation" then FakeTransport::Reply.json(OPERATION)
    when "page" then FakeTransport::Reply.json({ "items" => [RECORD], "nextCursor" => nil })
    else FakeTransport::Reply.json(RECORD)
    end
  end

  # Runs +source+ in an empty directory holding roster.csv, with every
  # client's transport replaced by +fake+, and returns what it printed and
  # the files it wrote.
  def run_sample(source, fake)
    saved_env = ENVIRONMENT.keys.to_h { |name| [name, ENV.fetch(name, nil)] }
    saved_stdout = $stdout
    stdout = StringIO.new
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("roster.csv", "email,name\r\ndana.whitfield@example.com,Dana Whitfield\r\n")
        ENV.update(ENVIRONMENT)
        $stdout = stdout
        SampleTransport.using(fake) { Object.new.instance_eval(source) }
        [stdout.string.lines(chomp: true), Dir.children(dir) - ["roster.csv"]]
      ensure
        $stdout = saved_stdout
        ENV.update(saved_env)
      end
    end
  end

  def sandbox_api
    FakeTransport.new(SANDBOX_BASE)
                 .on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
                 .on("GET", "/auth/introspection", FakeTransport::Reply.json(introspection_json))
  end
end
