# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/sample_transport"
require_relative "support/doc_samples"
require "logger"
require "rack/mock"
require "stringio"
require "tmpdir"

# Keeps the README and the guides in docs/guides honest. Every fenced ruby
# block must follow a "<!-- sample: id -->" line (see DocSamples). Every
# sample must compile, and each one either runs here against FakeTransport,
# with a check of what it printed and sent, runs in the Rails suite
# (test/rails), or is listed in SYNTAX_ONLY with the reason it can't run.
class ReadmeTest < Minitest::Test
  include ClientHelpers

  ROOT = DocSamples::ROOT
  SYNTAX_ONLY = {
    "install" => "a Gemfile",
    "rails/routes" => "a Rails routes file",
    "rails/integration-test" => "needs a Rails app",
  }.freeze
  # Run by test/rails/rails_guide_test.rb, which loads Action Pack and
  # Active Job; this suite stays free of Rails.
  RAILS_SUITE = %w[rails/initializer rails/job rails/webhook-controller].freeze
  SAMPLE_LEARNER_ID = "sub_01JD80AB2C3D4E5F6G7H8J9K0M"
  SAMPLE_LEARNER_PATH = "/organizations/#{ORG_ID}/learners/#{SAMPLE_LEARNER_ID}".freeze
  LEARNERS_PATH = "/organizations/#{ORG_ID}/learners".freeze
  COMPLIANCE_PATH = "/organizations/#{ORG_ID}/compliance".freeze
  OPERATION_NAME = "organizations/#{ORG_ID}/operations/op-01JD8H".freeze
  OPERATION_PATH = "/organizations/#{ORG_ID}/operations/op-01JD8H".freeze
  WEBHOOK_SECRET = "whsec_readme-test-secret"
  ENVIRONMENT = {
    "TMH_CLIENT_ID" => CLIENT_ID,
    "TMH_CLIENT_SECRET" => CLIENT_SECRET,
    "TMH_WEBHOOK_SECRET" => WEBHOOK_SECRET,
    "TMH_ACCESS_TOKEN" => ACCESS_TOKEN,
  }.freeze

  # Big enough to stream in several chunks.
  PDF = "%PDF-1.7\n#{"certificate " * 4096}%%EOF".b.freeze

  def self.samples = DocSamples.all

  def self.run_checks = @run_checks ||= []

  # Defines a test that runs sample +id+; registering it is what lets the
  # completeness test pass.
  def self.runs(id, behaviour, &)
    run_checks << id
    define_method("test_sample_#{id.tr("/-", "__")}_#{behaviour}", &)
  end

  # What a sample runs as: +puts+ is recorded, +client+ is the Quickstart's
  # client for samples that use one without creating it, and the stand-ins
  # the prose names (cursor_store, shutting_down?) are defined.
  class SampleContext
    CursorStore = Struct.new(:position, :saved) do
      def load = position

      def save(event_id)
        saved << event_id
      end
    end

    attr_reader :output, :cursor_store

    def initialize
      @output = []
      @cursor_store = CursorStore.new("evt_01JD8A", [])
    end

    def puts(*values)
      values = [""] if values.empty?
      values.flatten.each { |value| @output << value.to_s }
      nil
    end

    # The Quickstart's client, with a fake clock that its waits move
    # forward, so Operation#wait doesn't slow the suite.
    def client
      @client ||= begin
        clock = FakeClock.new
        TeachMeHipaa::Client.new(client_id: ENV.fetch("TMH_CLIENT_ID"),
                                 client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
                                 environment: :sandbox, clock:, sleep: FakeSleep.new(clock))
      end
    end

    def shutting_down?
      cursor_store.saved.length >= 2
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

    assert_equal expected, (self.class.run_checks.uniq + SYNTAX_ONLY.keys + RAILS_SUITE).sort
  end

  def test_every_guide_is_linked_from_the_readme_and_the_docs_index
    readme = File.read(File.join(ROOT, "README.md"))
    index = File.read(File.join(ROOT, "docs/README.md"))

    Dir[File.join(ROOT, "docs/guides/*.md")].each do |guide|
      name = File.basename(guide)

      assert_includes readme, "(docs/guides/#{name})"
      assert_includes index, "(guides/#{name})"
    end
  end

  # README

  runs "quickstart", "retrieves_a_learner_and_lists_every_page" do
    fake = sandbox_api
    fake.on("GET", SAMPLE_LEARNER_PATH, learner_reply)
    fake.on("GET", LEARNERS_PATH, learner_pages)

    output = run_sample("quickstart", fake)

    assert_equal ["Ana Lima: in_progress", "ana@example.com", "ben@example.com", "cy@example.com"], output
    first, second = fake.requests_to("GET", LEARNERS_PATH).map { |request| query(request) }

    assert_equal({ "status" => "in_progress" }, first)
    assert_equal({ "status" => "in_progress", "cursor" => "c2" }, second)
    assert sandbox?(fake.requests.first)
  end

  # Models, pages and ETags

  runs "models-and-pages/responses", "reads_fields_and_the_last_response" do
    fake = sandbox_api.on("GET", SAMPLE_LEARNER_PATH, learner_reply)

    assert_equal ["ana@example.com", "HIPAA Essentials", "not certified yet", REQUEST_ID, "in_progress"],
                 run_sample("models-and-pages/responses", fake)
  end

  # Setting up a client

  runs "client/client-credentials", "introspects_the_minted_token" do
    fake = sandbox_api

    assert_equal [CLIENT_ID, "learners:read learners:write"], run_sample("client/client-credentials", fake)
    assert_equal "Basic #{BASIC_CREDENTIALS}", fake.requests_to("POST", "/auth/token").first.headers["authorization"]
  end

  runs "client/scopes", "asks_for_fewer_scopes_and_reports_a_missing_one" do
    fake = live_api.on("POST", LEARNERS_PATH, problem(403, "insufficient_scope", detail: "Needs learners:write"))

    assert_equal ["insufficient_scope: Needs learners:write"], run_sample("client/scopes", fake)
    form = URI.decode_www_form(only(fake.requests_to("POST", "/auth/token")).body).to_h

    assert_equal "learners:read compliance:read", form["scope"]
  end

  runs "client/organization", "skips_the_organization_lookup" do
    fake = FakeTransport.new.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    fake.on("GET", COMPLIANCE_PATH, compliance_reply)

    assert_equal ["0.92", REQUEST_ID], run_sample("client/organization", fake)
    assert_empty fake.requests_to("GET", "/auth/introspection")
  end

  runs "client/static-token", "sends_the_given_token_without_minting" do
    fake = FakeTransport.new(SANDBOX_BASE).on("GET", "/auth/introspection",
                                              FakeTransport::Reply.json(introspection_json))

    assert_equal ["2026-11-15 12:15:00 UTC"], run_sample("client/static-token", fake)
    assert_equal "Bearer #{ACCESS_TOKEN}", only(fake.requests).headers["authorization"]
  end

  runs "client/no-credentials", "calls_the_catalog_and_verifications_without_a_token" do
    course = { "courseId" => "hipaa-2026", "title" => "HIPAA Essentials", "courseVersion" => "2026.1",
               "passingThreshold" => 0.8 }
    verification = { "status" => "valid", "learnerName" => "Ana Lima", "courseTitle" => "HIPAA Essentials",
                     "issuedAt" => "2026-11-10T15:00:00Z", "expiresAt" => "2027-11-10T15:00:00Z",
                     "issuer" => "TeachMeHIPAA" }
    fake = FakeTransport.new(SANDBOX_BASE)
                        .on("GET", "/courses", FakeTransport::Reply.json({ "items" => [course], "nextCursor" => nil }))
                        .on("GET", "/certificate-verifications/x7Kq2p", FakeTransport::Reply.json(verification))

    assert_equal ["HIPAA Essentials", "valid"], run_sample("client/no-credentials", fake)
    assert_equal([nil, nil], fake.requests.map { |request| request.headers["authorization"] })
  end

  # Errors and retries

  runs "errors/errors", "branches_on_the_error_class" do
    {
      problem(404, "not_found", title: "Not found") => ["No such Learner"],
      problem(403, "insufficient_scope", detail: "Needs learners:read") => ["Missing a Scope: Needs learners:read"],
      problem(422, "validation_failed", detail: "Invalid courseId",
                                        errors: [{ "path" => "courseId", "message" => "is too long" }]) =>
        ["validation_failed: Invalid courseId (request #{REQUEST_ID})", "courseId: is too long"],
    }.each do |reply, expected|
      fake = sandbox_api.on("GET", SAMPLE_LEARNER_PATH, reply)

      assert_equal expected, run_sample("errors/errors", fake)
    end
  end

  runs "errors/error-codes", "branches_on_known_codes_and_reraises_the_rest" do
    {
      "seat_unavailable" => ["No free Seat; ask an admin to add Seats"],
      "external_id_conflict" => ["hr-123 already belongs to another Learner"],
    }.each do |code, expected|
      fake = sandbox_api.on("POST", LEARNERS_PATH, problem(409, code))

      assert_equal expected, run_sample("errors/error-codes", fake)
    end
    fake = sandbox_api.on("POST", LEARNERS_PATH, problem(409, "already_invited"))
    error = assert_raises(TeachMeHipaa::ConflictError) { run_sample("errors/error-codes", fake) }

    assert_equal "already_invited", error.code
  end

  runs "errors/request-id", "sends_and_reads_back_the_request_id" do
    fake = sandbox_api.on("GET", LEARNERS_PATH,
                          FakeTransport::Reply.json({ "items" => [], "nextCursor" => nil },
                                                    headers: { "x-request-id" => "hr-sync-42" }))

    assert_equal ["hr-sync-42"], run_sample("errors/request-id", fake)
    assert_equal "hr-sync-42", only(fake.requests_to("GET", LEARNERS_PATH)).headers["x-request-id"]
  end

  runs "errors/max-retries", "sets_the_budget_per_client_and_per_call" do
    fake = sandbox_api.on("GET", COMPLIANCE_PATH, compliance_reply)

    assert_equal %w[4 0.92], run_sample("errors/max-retries", fake)

    fake = sandbox_api.on("GET", COMPLIANCE_PATH, problem(503, "temporarily_unavailable"))

    assert_raises(TeachMeHipaa::APIError) { run_sample("errors/max-retries", fake) }
    assert_equal 1, fake.requests_to("GET", COMPLIANCE_PATH).length
  end

  runs "errors/request-options", "sends_the_key_and_request_id_it_was_given" do
    fake = sandbox_api
    fake.on("POST", "/organizations/#{ORG_ID}/enrollments",
            FakeTransport::Reply.json({ "enrollmentId" => "sub_x__hipaa-2026" },
                                      status: 201, headers: { "x-request-id" => "hr-sync-42" }))

    assert_equal %w[sub_x__hipaa-2026 hr-sync-42], run_sample("errors/request-options", fake)
    request = only(fake.requests_to("POST", "/organizations/#{ORG_ID}/enrollments"))

    assert_equal "hr-sync-2026-11-15-ana", request.headers["idempotency-key"]
    assert_equal "hr-sync-42", request.headers["x-request-id"]
    assert_in_delta 10.0, request.timeout
  end

  runs "models-and-pages/one-page", "enumerates_one_page_then_fetches_the_next" do
    fake = sandbox_api.on("GET", LEARNERS_PATH, learner_pages)

    assert_equal ["2", "ana@example.com, ben@example.com", "cy@example.com"],
                 run_sample("models-and-pages/one-page", fake)
    assert_equal(%w[2 2], fake.requests_to("GET", LEARNERS_PATH).map { |request| query(request)["limit"] })
  end

  runs "models-and-pages/every-item", "walks_every_page" do
    fake = sandbox_api.on("GET", LEARNERS_PATH, learner_pages)

    assert_equal [LEARNER_ID, "sub_ben", "sub_cy"], run_sample("models-and-pages/every-item", fake)
    assert_equal 2, fake.requests_to("GET", LEARNERS_PATH).length
  end

  runs "models-and-pages/lazy", "fetches_pages_until_the_chain_is_satisfied" do
    fake = sandbox_api.on("GET", LEARNERS_PATH, learner_pages)

    assert_equal ["cy@example.com"], run_sample("models-and-pages/lazy", fake)
    assert_equal 2, fake.requests_to("GET", LEARNERS_PATH).length
  end

  runs "models-and-pages/each-page", "yields_each_page_with_its_response" do
    certificates = "/organizations/#{ORG_ID}/certificates"
    fake = sandbox_api
    fake.on("GET", certificates, FakeTransport::Reply.json({ "items" => [CERTIFICATE_JSON, CERTIFICATE_JSON],
                                                             "nextCursor" => "c2" },
                                                           headers: { "x-request-id" => "req_1" }))
    fake.on("GET", certificates, FakeTransport::Reply.json({ "items" => [CERTIFICATE_JSON], "nextCursor" => nil },
                                                           headers: { "x-request-id" => "req_2" }))

    assert_equal ["Page of 2 (request req_1)", "Page of 1 (request req_2)"],
                 run_sample("models-and-pages/each-page", fake)
    assert_equal(%w[100 100], fake.requests_to("GET", certificates).map { |request| query(request)["limit"] })
  end

  # Events and webhooks

  runs "events-and-webhooks/events-list", "lists_one_event_type" do
    fake = sandbox_api.on("GET", events_path, FakeTransport::Reply.json({ "items" => [certified_event_json] }))

    assert_equal ["2026-11-15T12:00:00Z ana@example.com"], run_sample("events-and-webhooks/events-list", fake)
    assert_equal "learner.certified", query(only(fake.requests_to("GET", events_path)))["type"]
  end

  runs "events-and-webhooks/event-types", "dispatches_on_the_event_class_with_a_fallback" do
    events = [certified_event_json, event_json("evt_02", "learner.expiring", "email" => "ben@example.com"),
              event_json("evt_03", "seat.freed"), event_json("evt_04", "learner.teleported")]
    fake = sandbox_api.on("GET", events_path, FakeTransport::Reply.json({ "items" => events }))

    assert_equal ["ana@example.com is certified", "ben@example.com needs to renew", "skipped seat.freed",
                  "skipped learner.teleported"], run_sample("events-and-webhooks/event-types", fake)
  end

  runs "events-and-webhooks/events-tail", "resumes_from_the_saved_position_and_saves_each_event" do
    fake = sandbox_api
    events = [event_json("evt_01JD8B", "learner.started"), event_json("evt_01JD8C", "learner.certified")]
    fake.on("GET", events_path, FakeTransport::Reply.json({ "items" => events }))
    context = SampleContext.new

    output = run_sample("events-and-webhooks/events-tail", fake, context:)

    assert_equal ["learner.started evt_01JD8B", "learner.certified evt_01JD8C"], output
    assert_equal %w[evt_01JD8B evt_01JD8C], context.cursor_store.saved
    assert_equal "evt_01JD8A", query(fake.requests_to("GET", events_path).first)["after"]
  end

  runs "events-and-webhooks/create-subscription", "creates_it_and_shows_the_signing_secret_once" do
    path = "/organizations/#{ORG_ID}/webhook-subscriptions"
    created = { "subscriptionId" => "whs_01JD8D", "endpointUrl" => "https://hr.example.com/webhooks/tmh",
                "eventTypes" => %w[learner.certified learner.expiring], "enabled" => true,
                "secret" => WEBHOOK_SECRET }
    fake = sandbox_api.on("POST", path, FakeTransport::Reply.json(created, status: 201))

    assert_equal ["whs_01JD8D", WEBHOOK_SECRET], run_sample("events-and-webhooks/create-subscription", fake)
    assert_equal({ "endpointUrl" => "https://hr.example.com/webhooks/tmh",
                   "eventTypes" => %w[learner.certified learner.expiring], "description" => "HR system" },
                 JSON.parse(only(fake.requests_to("POST", path)).body))
  end

  runs "events-and-webhooks/webhook-sinatra", "verifies_deliveries_on_the_exact_path_they_were_signed_for" do
    context = SampleContext.new
    run_sample("events-and-webhooks/webhook-sinatra", FakeTransport.new, context:)
    app = Rack::MockRequest.new(context.singleton_class.const_get(:TmhWebhooks))
    path = "/webhooks/tmh?source=hr"

    signed = deliver(app, path, signed_for: path, payload: JSON.generate(certified_event_json))
    test_ping = deliver(app, path, signed_for: path,
                                   payload: JSON.generate("test" => true, "subscriptionId" => "whs_01JD8D"))
    wrong_path = deliver(app, path, signed_for: "/webhooks/tmh", payload: JSON.generate(certified_event_json))

    assert_equal [200, "received learner.certified"], [signed.status, signed.body]
    assert_equal [200, "test received"], [test_ping.status, test_ping.body]
    assert_equal [400, "signature_mismatch"], [wrong_path.status, wrong_path.body]
  end

  runs "events-and-webhooks/test-delivery", "reports_how_the_test_delivery_went" do
    {
      { "_tag" => "sent", "responseStatus" => 200 } => ["Your endpoint answered 200"],
      { "_tag" => "failed", "reason" => "endpoint_gone", "responseStatus" => 410 } =>
        ["Delivery failed: endpoint_gone"],
      { "_tag" => "deferred" } => ["deferred"],
    }.each do |result, expected|
      fake = sandbox_api
      fake.on("POST", "/organizations/#{ORG_ID}/webhook-subscriptions/whs_01JD8D:test",
              FakeTransport::Reply.json({ "name" => OPERATION_NAME, "done" => false }))
      fake.on("GET", OPERATION_PATH, FakeTransport::Reply.json({ "name" => OPERATION_NAME, "done" => true,
                                                                 "response" => result }))

      assert_equal expected, run_sample("events-and-webhooks/test-delivery", fake)
    end
  end

  runs "events-and-webhooks/webhook-test-headers", "verifies_the_payload_it_signed" do
    fake = FakeTransport.new

    assert_equal ["learner.certified", SAMPLE_LEARNER_ID], run_sample("events-and-webhooks/webhook-test-headers", fake)
    assert_empty fake.requests
  end

  # Operations and files

  runs "operations/export-wait", "saves_the_export_csv" do
    fake = sandbox_api.on("POST", "/organizations/#{ORG_ID}/certificates:export",
                          done_export("certificates-org_acme.csv"))

    in_tmpdir do
      assert_equal ["2 Certificates"], run_sample("operations/export-wait", fake)
      assert_equal export_csv, File.read("certificates-org_acme.csv")
    end
  end

  runs "operations/operation-errors", "reports_a_failed_operation" do
    fake = sandbox_api
    fake.on("POST", "/organizations/#{ORG_ID}/webhook-subscriptions/whs_01JD8D:redrive",
            FakeTransport::Reply.json({ "name" => OPERATION_NAME, "done" => true,
                                        "error" => { "title" => "Gone", "status" => 410, "code" => "endpoint_gone" } }))

    assert_equal ["Redrive failed: endpoint_gone"], run_sample("operations/operation-errors", fake)
  end

  runs "operations/operation-errors", "reports_an_operation_still_running_at_the_timeout" do
    fake = sandbox_api
    fake.on("POST", "/organizations/#{ORG_ID}/webhook-subscriptions/whs_01JD8D:redrive",
            FakeTransport::Reply.json({ "name" => OPERATION_NAME, "done" => false }))
    fake.on("GET", OPERATION_PATH, FakeTransport::Reply.json({ "name" => OPERATION_NAME, "done" => false }))

    assert_equal ["Still running; check #{OPERATION_NAME} later"],
                 run_sample("operations/operation-errors", fake)
  end

  runs "operations/operation-later", "retrieves_the_operation_by_its_id" do
    fake = sandbox_api.on("POST", "/organizations/#{ORG_ID}/learners:export", done_export("learners-org_acme.csv"))
    fake.on("GET", OPERATION_PATH, done_export("learners-org_acme.csv"))

    assert_equal ["true"], run_sample("operations/operation-later", fake)
    assert_equal 1, fake.requests_to("GET", OPERATION_PATH).length
  end

  runs "operations/export-learners", "exports_one_status" do
    path = "/organizations/#{ORG_ID}/learners:export"
    fake = sandbox_api.on("POST", path, done_export("learners-org_acme.csv"))

    assert_equal ["learners-org_acme.csv: 2 rows"], run_sample("operations/export-learners", fake)
    assert_equal({ "format" => "csv", "status" => "expired" }, JSON.parse(only(fake.requests_to("POST", path)).body))
  end

  runs "operations/pdf-download", "saves_the_pdf_whole_and_streamed" do
    fake = sandbox_api.on("GET", "/organizations/#{ORG_ID}/certificates/cert_01JD8F/content", pdf_reply)

    in_tmpdir do
      run_sample("operations/pdf-download", fake)

      assert_equal [PDF, PDF], [File.binread("certificate-7QX2.pdf"), File.binread("certificate-copy.pdf")]
    end
  end

  runs "operations/csv-import", "previews_and_uploads_rosters" do
    fake = sandbox_api.on("POST", "/organizations/#{ORG_ID}/enrollments:import", method(:import_reply))

    in_tmpdir do
      File.write("roster.csv", "email,name\r\nben@example.com,Ben\r\n")

      assert_equal ["2 of 3 rows are valid"], run_sample("operations/csv-import", fake)
    end
    uploads = fake.requests_to("POST", "/organizations/#{ORG_ID}/enrollments:import").map(&:body)

    assert_includes uploads[0], "ben@example.com"
    assert_includes uploads[1], 'filename="roster.csv"'
    assert_includes uploads[2], 'filename="march.csv"'
  end

  runs "models-and-pages/conditional-write", "sends_the_etag_it_read_and_clears_with_nil" do
    fake = sandbox_api.on("GET", SAMPLE_LEARNER_PATH, learner_reply)
    fake.on("PATCH", SAMPLE_LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON.merge("name" => "Ana Q. Example")))

    assert_equal ["Ana Q. Example"], run_sample("models-and-pages/conditional-write", fake)
    patch = only(fake.requests_to("PATCH", SAMPLE_LEARNER_PATH))

    assert_equal ETAG, patch.headers["if-match"]
    assert_equal({ "name" => "Ana Q. Example", "externalId" => nil }, JSON.parse(patch.body))
  end

  runs "models-and-pages/conditional-write", "reports_a_stale_etag" do
    fake = sandbox_api.on("GET", SAMPLE_LEARNER_PATH, learner_reply)
    fake.on("PATCH", SAMPLE_LEARNER_PATH, problem(412, "precondition_failed"))

    assert_equal ["Someone else changed this Learner; read it again"],
                 run_sample("models-and-pages/conditional-write", fake)
  end

  runs "models-and-pages/merge-patch", "sends_only_the_fields_that_changed" do
    fake = sandbox_api.on("GET", SAMPLE_LEARNER_PATH, learner_reply)
    fake.on("PATCH", SAMPLE_LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))

    assert_equal ["updated"], run_sample("models-and-pages/merge-patch", fake)
    patch = only(fake.requests_to("PATCH", SAMPLE_LEARNER_PATH))

    assert_equal({ "name" => "Ana Q. Example" }, JSON.parse(patch.body))
    assert_equal "application/merge-patch+json", patch.headers["content-type"]
  end

  runs "models-and-pages/not-modified", "keeps_the_copy_it_holds_on_a_304" do
    fake = sandbox_api
    course = { "courseId" => "hipaa-2026", "title" => "HIPAA Essentials" }
    fake.on("GET", "/courses/hipaa-2026", FakeTransport::Reply.json(course, headers: { "etag" => ETAG }))
    fake.on("GET", "/courses/hipaa-2026", FakeTransport::Reply.empty(status: 304, headers: { "etag" => ETAG }))

    assert_equal ["HIPAA Essentials"], run_sample("models-and-pages/not-modified", fake)
    assert_equal ETAG, fake.requests_to("GET", "/courses/hipaa-2026").last.headers["if-none-match"]
  end

  # Testing

  runs "testing/sandbox", "reads_the_token_mode" do
    fake = sandbox_api

    assert_equal ["test"], run_sample("testing/sandbox", fake)
    assert sandbox?(fake.requests.first)
  end

  runs "testing/fake-transport", "answers_from_canned_replies_without_the_network" do
    fake = FakeTransport.new

    assert_equal %w[0.75 not_found 2], run_sample("testing/fake-transport", fake)
    assert_empty fake.requests
  end

  runs "testing/sign-delivery", "posts_a_signed_test_delivery_to_the_webhooks_guide_app" do
    context = SampleContext.new
    run_sample("events-and-webhooks/webhook-sinatra", FakeTransport.new, context:)

    assert_equal ["200", "test received"], run_sample("testing/sign-delivery", FakeTransport.new, context:)
  end

  runs "client/configuration", "reads_back_the_frozen_settings" do
    output = run_sample("client/configuration", FakeTransport.new)

    assert_equal ["sandbox", SANDBOX_BASE, "3", "30.0", "true"], output
  end

  runs "client/per-call-timeout", "applies_the_options_to_one_call" do
    fake = sandbox_api.on("GET", COMPLIANCE_PATH, compliance_reply)

    assert_equal ["0.92"], run_sample("client/per-call-timeout", fake)
    request = only(fake.requests_to("GET", COMPLIANCE_PATH))

    assert_in_delta 5.0, request.timeout
    assert_equal "dashboard-refresh", request.headers["x-request-id"]
  end

  runs "client/tight-budget", "lowers_the_timeout" do
    assert_equal ["5.0"], run_sample("client/tight-budget", FakeTransport.new)
  end

  runs "client/logging", "logs_each_exchange_without_bodies" do
    fake = live_api.on("GET", LEARNERS_PATH,
                       FakeTransport::Reply.json({ "items" => [LEARNER_JSON], "nextCursor" => nil },
                                                 headers: { "x-request-id" => REQUEST_ID }))
    stdout = StringIO.new

    run_sample("client/logging", fake, stdout:)

    assert_match(%r{teachmehipaa\.request method=GET path=/v1#{LEARNERS_PATH} status=200 .*request_id=#{REQUEST_ID}},
                 stdout.string)
    refute_includes stdout.string, "ana@example.com"
    refute_includes stdout.string, ACCESS_TOKEN
  end

  # Versions and upgrades

  runs "upgrading/version", "prints_the_version" do
    assert_equal [TeachMeHipaa::VERSION], run_sample("upgrading/version", FakeTransport.new)
  end

  runs "upgrading/open-enums", "handles_known_and_unknown_values" do
    fake = sandbox_api.on("GET", SAMPLE_LEARNER_PATH,
                          FakeTransport::Reply.json(LEARNER_JSON.merge("status" => "paused", "someNewField" => "x")))

    assert_equal ["status paused", '"x"'], run_sample("upgrading/open-enums", fake)

    fake = sandbox_api.on("GET", SAMPLE_LEARNER_PATH,
                          FakeTransport::Reply.json(LEARNER_JSON.merge("status" => "compliant")))

    assert_equal %w[compliant nil], run_sample("upgrading/open-enums", fake)
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

  def in_tmpdir(&)
    Dir.mktmpdir { |dir| Dir.chdir(dir, &) }
  end

  def sandbox_api
    FakeTransport.new(SANDBOX_BASE)
                 .on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
                 .on("GET", "/auth/introspection", FakeTransport::Reply.json(introspection_json))
  end

  def live_api
    FakeTransport.new(LIVE_BASE)
                 .on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
                 .on("GET", "/auth/introspection", FakeTransport::Reply.json(introspection_json))
  end

  def sandbox?(request)
    request.url.start_with?(SANDBOX_BASE)
  end

  def query(request)
    URI.decode_www_form(URI(request.url).query.to_s).to_h
  end

  def learner_reply
    FakeTransport::Reply.json(LEARNER_JSON.merge("learnerId" => SAMPLE_LEARNER_ID),
                              headers: { "etag" => ETAG, "x-request-id" => REQUEST_ID })
  end

  def compliance_reply
    FakeTransport::Reply.json({ "asOf" => "2026-11-15T12:00:00Z", "courseId" => "hipaa-2026",
                                "compliantRate" => 0.92 }, headers: { "x-request-id" => REQUEST_ID })
  end

  # Two pages of Learners, picked by the cursor each request carries; only
  # the second page's Learner holds a Certificate.
  def learner_pages
    first = { "items" => [LEARNER_JSON, LEARNER_JSON.merge("learnerId" => "sub_ben", "email" => "ben@example.com")],
              "nextCursor" => "c2" }
    second = { "items" => [LEARNER_JSON.merge("learnerId" => "sub_cy", "email" => "cy@example.com",
                                              "certificate" => CERTIFICATE_JSON)],
               "nextCursor" => nil }
    lambda do |request|
      FakeTransport::Reply.json(query(request)["cursor"] == "c2" ? second : first)
    end
  end

  def export_csv
    "email,status\r\nana@example.com,certified\r\nben@example.com,in_progress\r\n"
  end

  # A done export Operation, carrying the monorepo's ExportArtifact for a
  # two-row CSV.
  def done_export(filename)
    artifact = { "format" => "csv", "contentType" => "text/csv", "filename" => filename, "rowCount" => 2,
                 "dataBase64" => [export_csv].pack("m0") }
    FakeTransport::Reply.json({ "name" => OPERATION_NAME, "done" => true, "response" => artifact })
  end

  # A preview (validateOnly) or a done import Operation.
  def import_reply(request)
    if request.body.include?('"validateOnly":true')
      return FakeTransport::Reply.json({ "totalRows" => 3, "validRows" => 2 })
    end

    FakeTransport::Reply.json({ "name" => "organizations/#{ORG_ID}/operations/op-import", "done" => true })
  end

  def pdf_reply
    FakeTransport::Reply.new(status: 200, body: PDF, content_type: "application/pdf",
                             headers: { "content-disposition" => 'attachment; filename="certificate-7QX2.pdf"' })
  end

  def events_path
    "/organizations/#{ORG_ID}/events"
  end

  def event_json(event_id, event_type, data = {})
    { "eventId" => event_id, "eventType" => event_type, "orgId" => ORG_ID, "occurredAt" => "2026-11-15T12:00:00Z",
      "data" => { "learnerId" => SAMPLE_LEARNER_ID }.merge(data) }
  end

  def certified_event_json
    event_json("evt_01JD8C", "learner.certified", "email" => "ana@example.com")
  end

  # POSTs +payload+ to +path+ with the headers TeachMeHIPAA would send to
  # +signed_for+, as a Rack server hands them to the app.
  def deliver(app, path, signed_for:, payload:)
    headers = TeachMeHipaa::Webhook.generate_test_headers(payload:, secret: WEBHOOK_SECRET, path: signed_for)
    env = headers.to_h { |name, value| ["HTTP_#{name.upcase.tr("-", "_")}", value] }
    saved = ENV.fetch("TMH_WEBHOOK_SECRET", nil)
    ENV["TMH_WEBHOOK_SECRET"] = WEBHOOK_SECRET
    app.post("http://localhost#{path}", env.merge(input: payload, "CONTENT_TYPE" => "application/json"))
  ensure
    ENV["TMH_WEBHOOK_SECRET"] = saved
  end
end
