# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/sample_transport"
require "rack/mock"
require "stringio"
require "tmpdir"

# Keeps examples/ working: every program compiles, and each one runs against
# FakeTransport with the credentials it reads from the environment, with a
# check of what it printed and sent.
class ExamplesTest < Minitest::Test
  include ClientHelpers

  EXAMPLES = File.expand_path("../examples", __dir__)
  WEBHOOK_SECRET = "whsec_examples-test-secret"
  ENVIRONMENT = {
    "TMH_CLIENT_ID" => CLIENT_ID,
    "TMH_CLIENT_SECRET" => CLIENT_SECRET,
    "TMH_WEBHOOK_SECRET" => WEBHOOK_SECRET,
  }.freeze
  LEARNERS_PATH = "/organizations/#{ORG_ID}/learners".freeze
  OPERATION_NAME = "organizations/#{ORG_ID}/operations/op-01JD8H".freeze
  EXPORT_CSV = "certificateId,email\r\ncrt_1,ana@example.com\r\n"

  def test_every_example_compiles_and_is_run_here
    examples = Dir[File.join(EXAMPLES, "*.rb")].map { |path| File.basename(path) }

    examples.each { |name| RubyVM::InstructionSequence.compile_file(File.join(EXAMPLES, name)) }

    assert_equal %w[export_certificates.rb quickstart.rb sync_roster.rb webhook_sinatra.rb], examples.sort
  end

  def test_quickstart_lists_courses_compliance_and_learners_in_the_sandbox
    fake = sandbox_api
    fake.on("GET", "/courses", FakeTransport::Reply.json({ "items" => [{ "courseId" => "hipaa-2026",
                                                                         "title" => "HIPAA Essentials" }] }))
    fake.on("GET", "/organizations/#{ORG_ID}/compliance", FakeTransport::Reply.json({ "compliantRate" => 0.5 }))
    fake.on("GET", LEARNERS_PATH, FakeTransport::Reply.json({ "items" => [LEARNER_JSON], "nextCursor" => nil }))

    output = run_example("quickstart.rb", fake)

    assert_equal ["Courses:", "  hipaa-2026: HIPAA Essentials", "50% of Learners are compliant", "First Learners:",
                  "  ana@example.com (in_progress)"], output.lines(chomp: true)
    assert(fake.requests.all? { |request| request.url.start_with?(SANDBOX_BASE) })
  end

  def test_sync_roster_upserts_everyone_and_offboards_learners_who_left
    fake = sandbox_api
    fake.on("PUT", "#{LEARNERS_PATH}/by-external-id/hr-1001", learner("hr-1001", "ana@example.com", status: 201))
    fake.on("PUT", "#{LEARNERS_PATH}/by-external-id/hr-1002", learner("hr-1002", "ben@example.com"))
    fake.on("PUT", "#{LEARNERS_PATH}/by-external-id/hr-1003", problem(409, "seat_unavailable"))
    listed = [%w[sub_ana hr-1001 in_progress], %w[sub_gone hr-0999 compliant], %w[sub_out hr-0998 removed],
              ["sub_manual", nil, "in_progress"]].map do |id, external_id, status|
      LEARNER_JSON.merge("learnerId" => id, "externalId" => external_id, "status" => status,
                         "email" => "#{id}@example.com")
    end
    fake.on("GET", LEARNERS_PATH, FakeTransport::Reply.json({ "items" => listed, "nextCursor" => nil }))
    fake.on("POST", "#{LEARNERS_PATH}/sub_gone:offboard", FakeTransport::Reply.json(LEARNER_JSON))

    output = run_example("sync_roster.rb", fake)

    assert_equal ["invited: ana@example.com", "already enrolled: ben@example.com", "offboarded: sub_gone@example.com"],
                 output.lines(chomp: true)
    assert_equal({ "email" => "ana@example.com", "name" => "Ana Example" },
                 JSON.parse(only(fake.requests_to("PUT", "#{LEARNERS_PATH}/by-external-id/hr-1001")).body))
    assert_equal(1, fake.requests.count { |request| request.url.include?(":offboard") })
  end

  def test_export_certificates_waits_and_saves_the_csv_privately
    fake = sandbox_api
    artifact = { "format" => "csv", "filename" => "certificates-org_acme.csv", "rowCount" => 1,
                 "dataBase64" => [EXPORT_CSV].pack("m0") }
    fake.on("POST", "/organizations/#{ORG_ID}/certificates:export",
            FakeTransport::Reply.json({ "name" => OPERATION_NAME, "done" => true, "response" => artifact }))

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        output = run_example("export_certificates.rb", fake)

        assert_equal "Saved 1 rows to certificates-org_acme.csv\n", output
        assert_equal EXPORT_CSV, File.read("certificates-org_acme.csv")
        assert_equal 0o600, File.stat("certificates-org_acme.csv").mode & 0o777
      end
    end
  end

  def test_webhook_sinatra_verifies_and_dispatches_deliveries
    namespace = Module.new
    run_example("webhook_sinatra.rb", FakeTransport.new, wrap: namespace)
    app = Rack::MockRequest.new(namespace.const_get(:TmhWebhookApp))
    event = JSON.generate("eventId" => "evt_1", "eventType" => "learner.certified", "orgId" => ORG_ID,
                          "occurredAt" => "2026-11-15T12:00:00Z", "data" => { "email" => "ana@example.com" })
    test_ping = JSON.generate("test" => true, "subscriptionId" => "whs_01JD8D")

    assert_equal 204, deliver(app, "/webhooks/tmh", event).status
    assert_equal 204, deliver(app, "/webhooks/tmh", test_ping).status
    rejected = deliver(app, "/webhooks/tmh", event, signed_for: "/elsewhere")

    assert_equal [400, "signature_mismatch"], [rejected.status, rejected.body]
  end

  private

  # Runs examples/+name+ with every client pointed at +fake+ and the
  # credentials set, and returns what it printed to stdout. Its top-level
  # constants land in +wrap+ (an anonymous module unless given).
  def run_example(name, fake, wrap: true)
    saved_env = ENVIRONMENT.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    saved_stdout = $stdout
    saved_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    ENV.update(ENVIRONMENT)
    SampleTransport.using(fake) { load(File.join(EXAMPLES, name), wrap) }
    $stdout.string
  ensure
    $stdout = saved_stdout
    $stderr = saved_stderr
    ENV.update(saved_env)
  end

  def sandbox_api
    FakeTransport.new(SANDBOX_BASE)
                 .on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
                 .on("GET", "/auth/introspection", FakeTransport::Reply.json(introspection_json))
  end

  def learner(external_id, email, status: 200)
    FakeTransport::Reply.json(LEARNER_JSON.merge("externalId" => external_id, "email" => email), status:)
  end

  def deliver(app, path, payload, signed_for: path)
    headers = TeachMeHipaa::Webhook.generate_test_headers(payload:, secret: WEBHOOK_SECRET, path: signed_for)
    env = headers.to_h { |key, value| ["HTTP_#{key.upcase.tr("-", "_")}", value] }
    saved = ENV.fetch("TMH_WEBHOOK_SECRET", nil)
    ENV["TMH_WEBHOOK_SECRET"] = WEBHOOK_SECRET
    app.post(path, env.merge(input: payload, "CONTENT_TYPE" => "application/json"))
  ensure
    ENV["TMH_WEBHOOK_SECRET"] = saved
  end
end
