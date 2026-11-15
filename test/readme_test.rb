# frozen_string_literal: true

require_relative "test_helper"
require "logger"
require "rack/mock"
require "stringio"
require "tmpdir"

# Every Transport::NetHttp, including the ones README samples create through
# their own clients and OAuth calls, sends to the current sample run's fake
# instead of the network.
module ReadmeTransport
  def call(request, &)
    fake = Thread.current[:teachmehipaa_readme_transport]
    return super if fake.nil?

    fake.call(request, &)
  end
end
TeachMeHipaa::Transport::NetHttp.prepend(ReadmeTransport)

# Keeps the README honest. Every fenced ruby block must follow a
# "<!-- sample: id -->" line. Every sample must compile, and each one either
# runs against FakeTransport, with a check of what it printed and sent, or
# is listed in SYNTAX_ONLY with the reason it can't run here.
class ReadmeTest < Minitest::Test
  include ClientHelpers

  README = File.expand_path("../README.md", __dir__)
  SYNTAX_ONLY = {
    "install" => "a Gemfile",
    "webhook-rails" => "needs Rails",
  }.freeze
  SAMPLE_LEARNER_ID = "sub_01JD80AB2C3D4E5F6G7H8J9K0M"
  SAMPLE_LEARNER_PATH = "/organizations/#{ORG_ID}/learners/#{SAMPLE_LEARNER_ID}".freeze
  LEARNERS_PATH = "/organizations/#{ORG_ID}/learners".freeze
  WEBHOOK_SECRET = "whsec_readme-test-secret"
  ENVIRONMENT = {
    "TMH_CLIENT_ID" => CLIENT_ID,
    "TMH_CLIENT_SECRET" => CLIENT_SECRET,
    "TMH_APP_ID" => APP_ID,
    "TMH_APP_SECRET" => APP_SECRET,
    "TMH_WEBHOOK_SECRET" => WEBHOOK_SECRET,
  }.freeze

  # Big enough to stream in several chunks.
  PDF = "%PDF-1.7\n#{"certificate " * 4096}%%EOF".b.freeze

  Sample = Data.define(:id, :code, :line)

  # The README's fenced ruby blocks, by sample id. A block without a tag is
  # kept under nil so the tagging test can name it.
  def self.samples
    @samples ||= begin
      lines = File.readlines(README)
      lines.each_index.filter_map do |index|
        next unless lines[index].start_with?("```ruby")

        tag = lines[index - 1][/\A<!-- sample: ([\w-]+) -->/, 1]
        body = lines[(index + 1)..].take_while { |line| !line.start_with?("```") }
        Sample.new(id: tag, code: body.join, line: index + 2)
      end
    end
  end

  def self.run_checks = @run_checks ||= []

  # Defines a test that runs sample +id+; registering it is what lets the
  # completeness test pass.
  def self.runs(id, behaviour, &)
    run_checks << id
    define_method("test_readme_sample_#{id.tr("-", "_")}_#{behaviour}", &)
  end

  # Reads and writes Grant rows like an ActiveRecord model would, for the
  # partner samples' OrganizationGrant.
  class GrantRows
    Row = Struct.new(:rows, :org_id, :refresh_token) do
      def update!(refresh_token:)
        self.refresh_token = refresh_token
        rows[org_id] = refresh_token
      end
    end

    attr_reader :rows

    def initialize(rows = {})
      @rows = rows
    end

    def create!(org_id:, refresh_token:)
      @rows[org_id] = refresh_token
    end

    def find_by!(org_id:)
      Row.new(@rows, org_id, @rows.fetch(org_id))
    end
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

    # The Quickstart's client, with waits skipped so Operation#wait doesn't
    # slow the suite.
    def client
      @client ||= TeachMeHipaa::Client.new(client_id: ENV.fetch("TMH_CLIENT_ID"),
                                           client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
                                           environment: :sandbox, sleep: ->(_seconds) {})
    end

    def shutting_down?
      cursor_store.saved.length >= 2
    end
  end

  def test_every_ruby_block_is_a_tagged_sample
    untagged = self.class.samples.select { |sample| sample.id.nil? }.map(&:line)

    assert_empty untagged, "README ruby blocks at these lines need a <!-- sample: id --> line"
    ids = self.class.samples.map(&:id)

    assert_equal ids.uniq, ids, "sample ids must be unique"
  end

  def test_every_sample_compiles
    self.class.samples.each do |sample|
      RubyVM::InstructionSequence.compile(sample.code, README, README, sample.line)
    rescue SyntaxError => e
      flunk "sample #{sample.id} does not compile: #{e.message}"
    end
  end

  def test_every_sample_is_run_or_named_as_syntax_only
    expected = self.class.samples.filter_map(&:id).sort

    assert_equal expected, (self.class.run_checks.uniq + SYNTAX_ONLY.keys).sort
  end

  runs "quickstart", "retrieves_a_learner_and_lists_every_page" do
    fake = sandbox_api
    fake.on("GET", SAMPLE_LEARNER_PATH, learner_reply)
    fake.on("GET", LEARNERS_PATH, learner_pages)

    output = run_sample("quickstart", fake)

    assert_equal ["Ana Lima: in_progress", "ana@example.com", "ben@example.com", "cy@example.com"], output
    first, second = fake.requests_to("GET", LEARNERS_PATH).map { |request| query(request) }

    assert_equal({ "status" => "in_progress", "limit" => "20" }, first)
    assert_equal({ "status" => "in_progress", "limit" => "20", "cursor" => "c2" }, second)
    assert sandbox?(fake.requests.first)
  end

  runs "organization", "skips_the_organization_lookup" do
    fake = FakeTransport.new.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    fake.on("GET", "/organizations/#{ORG_ID}/compliance",
            FakeTransport::Reply.json({ "asOf" => "2026-11-15T12:00:00Z", "courseId" => "hipaa-2026",
                                        "compliantRate" => 0.92 }, headers: { "x-request-id" => REQUEST_ID }))

    assert_equal ["0.92", REQUEST_ID], run_sample("organization", fake)
    assert_empty fake.requests_to("GET", "/auth/introspection")
  end

  runs "learner-writes", "says_whether_each_write_created_the_learner" do
    fake = sandbox_api
    fake.on("POST", LEARNERS_PATH, FakeTransport::Reply.json(LEARNER_JSON, status: 201))
    fake.on("PUT", "#{LEARNERS_PATH}/by-external-id/hr-123", FakeTransport::Reply.json(LEARNER_JSON))

    assert_equal ["invited", LEARNER_ID], run_sample("learner-writes", fake)
    assert_equal({ "email" => "ana@example.com", "name" => "Ana Example", "courseId" => "hipaa-2026" },
                 JSON.parse(only(fake.requests_to("POST", LEARNERS_PATH)).body))
  end

  runs "pagination", "walks_every_page_lazily_and_page_by_page" do
    fake = sandbox_api
    fake.on("GET", LEARNERS_PATH, learner_pages)
    enrollments = "/organizations/#{ORG_ID}/enrollments"
    fake.on("GET", enrollments, FakeTransport::Reply.json({ "items" => [{}, {}], "nextCursor" => "e2" }))
    fake.on("GET", enrollments, FakeTransport::Reply.json({ "items" => [{}], "nextCursor" => nil }))

    output = run_sample("pagination", fake)

    assert_equal [LEARNER_ID, "sub_ben", "sub_cy", "1", "2", "1"], output
    assert_equal 2, fake.requests_to("GET", enrollments).length
  end

  runs "errors", "branches_on_the_error_class" do
    {
      problem(404, "not_found", title: "Not found") => ["No such Learner"],
      problem(403, "insufficient_scope", detail: "Needs learners:read") => ["Missing a Scope: Needs learners:read"],
      problem(422, "validation_failed", detail: "Invalid courseId",
                                        errors: [{ "path" => "courseId", "message" => "is too long" }]) =>
        ["validation_failed: Invalid courseId (request #{REQUEST_ID})", "courseId: is too long"],
    }.each do |reply, expected|
      fake = sandbox_api.on("GET", SAMPLE_LEARNER_PATH, reply)

      assert_equal expected, run_sample("errors", fake)
    end
  end

  runs "request-options", "sends_the_key_and_request_id_it_was_given" do
    fake = sandbox_api
    fake.on("POST", "/organizations/#{ORG_ID}/enrollments",
            FakeTransport::Reply.json({ "enrollmentId" => "sub_x__hipaa-2026" },
                                      status: 201, headers: { "x-request-id" => "hr-sync-42" }))

    assert_equal %w[sub_x__hipaa-2026 hr-sync-42], run_sample("request-options", fake)
    request = only(fake.requests_to("POST", "/organizations/#{ORG_ID}/enrollments"))

    assert_equal "hr-sync-2026-11-15-ana", request.headers["idempotency-key"]
    assert_equal "hr-sync-42", request.headers["x-request-id"]
    assert_in_delta 10.0, request.timeout
  end

  runs "conditional-write", "sends_the_etag_it_read_and_clears_with_nil" do
    fake = sandbox_api.on("GET", SAMPLE_LEARNER_PATH, learner_reply)
    fake.on("PATCH", SAMPLE_LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON.merge("name" => "Ana Q. Example")))

    assert_equal ["Ana Q. Example"], run_sample("conditional-write", fake)
    patch = only(fake.requests_to("PATCH", SAMPLE_LEARNER_PATH))

    assert_equal ETAG, patch.headers["if-match"]
    assert_equal({ "name" => "Ana Q. Example", "externalId" => nil }, JSON.parse(patch.body))
  end

  runs "conditional-write", "reports_a_stale_etag" do
    fake = sandbox_api.on("GET", SAMPLE_LEARNER_PATH, learner_reply)
    fake.on("PATCH", SAMPLE_LEARNER_PATH, problem(412, "precondition_failed"))

    assert_equal ["Someone else changed this Learner; read it again"], run_sample("conditional-write", fake)
  end

  runs "not-modified", "keeps_the_copy_it_holds_on_a_304" do
    fake = sandbox_api
    course = { "courseId" => "hipaa-2026", "title" => "HIPAA Essentials" }
    fake.on("GET", "/courses/hipaa-2026", FakeTransport::Reply.json(course, headers: { "etag" => ETAG }))
    fake.on("GET", "/courses/hipaa-2026", FakeTransport::Reply.empty(status: 304, headers: { "etag" => ETAG }))

    assert_equal ["HIPAA Essentials"], run_sample("not-modified", fake)
    assert_equal ETAG, fake.requests_to("GET", "/courses/hipaa-2026").last.headers["if-none-match"]
  end

  runs "operations", "reads_an_export_and_waits_for_a_test_delivery" do
    fake = sandbox_api
    operation = "organizations/#{ORG_ID}/operations/op-01JD8H"
    fake.on("POST", "/organizations/#{ORG_ID}/learners:export",
            FakeTransport::Reply.json({ "name" => operation, "done" => true, "response" => export_artifact }))
    fake.on("POST", "/organizations/#{ORG_ID}/webhook-subscriptions/whs_01JD8D:test",
            FakeTransport::Reply.json({ "name" => operation, "done" => false }))
    fake.on("GET", "/organizations/#{ORG_ID}/operations/op-01JD8H",
            FakeTransport::Reply.json({ "name" => operation, "done" => true,
                                        "response" => { "_tag" => "sent", "responseStatus" => 200 } }))

    assert_equal ["learners-org_acme.csv: 2 rows", "sent"], run_sample("operations", fake)
  end

  runs "files", "uploads_rosters_and_saves_certificate_pdfs" do
    fake = sandbox_api
    fake.on("POST", "/organizations/#{ORG_ID}/enrollments:import", method(:import_reply))
    fake.on("GET", "/organizations/#{ORG_ID}/certificates/cert_01JD8F/content", pdf_reply)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("roster.csv", "email,name\r\nben@example.com,Ben\r\n")

        assert_equal ["2 of 3 rows are valid"], run_sample("files", fake)
        assert_equal [PDF, PDF], [File.binread("certificate-7QX2.pdf"), File.binread("certificate-copy.pdf")]
      end
    end
    uploads = fake.requests_to("POST", "/organizations/#{ORG_ID}/enrollments:import").map(&:body)

    assert_includes uploads[0], "ben@example.com"
    assert_includes uploads[1], 'filename="roster.csv"'
    assert_includes uploads[2], 'filename="march.csv"'
  end

  runs "webhook-sinatra", "verifies_deliveries_on_the_exact_path_they_were_signed_for" do
    context = SampleContext.new
    run_sample("webhook-sinatra", FakeTransport.new, context:)
    app = Rack::MockRequest.new(context.singleton_class.const_get(:TmhWebhooks))
    path = "/webhooks/tmh?source=hr"

    signed = deliver(app, path, signed_for: path, payload: certified_event)
    test_ping = deliver(app, path, signed_for: path,
                                   payload: JSON.generate("test" => true, "subscriptionId" => "whs_01JD8D"))
    wrong_path = deliver(app, path, signed_for: "/webhooks/tmh", payload: certified_event)

    assert_equal [200, "received learner.certified"], [signed.status, signed.body]
    assert_equal [200, "test received"], [test_ping.status, test_ping.body]
    assert_equal [400, "signature_mismatch"], [wrong_path.status, wrong_path.body]
  end

  runs "webhook-test-headers", "verifies_the_payload_it_signed" do
    fake = FakeTransport.new

    assert_equal ["learner.certified", SAMPLE_LEARNER_ID], run_sample("webhook-test-headers", fake)
    assert_empty fake.requests
  end

  runs "partner-consent", "builds_the_consent_url_and_saves_the_grant" do
    context = SampleContext.new
    grants = GrantRows.new
    context.singleton_class.const_set(:OrganizationGrant, grants)
    fake = FakeTransport.new.on("POST", "/auth/token", grant_token_reply(ACCESS_TOKEN, REFRESH_TOKEN_1))
    session = {}
    url = consent = nil

    run_sample("partner-consent", fake, context:) do
      url = URI(context.start_consent(session))
      consent = URI.decode_www_form(url.query).to_h
      context.finish_consent(session, code: "code_7QX2", state: consent["state"], org_id: ORG_ID)
    end

    assert_equal "https://console.teachmehipaa.com/oauth/authorize", "#{url.scheme}://#{url.host}#{url.path}"
    assert_equal [APP_ID, "https://partner.example.com/tmh/callback"], consent.values_at("client_id", "redirect_uri")
    assert_equal({ ORG_ID => REFRESH_TOKEN_1 }, grants.rows)
    assert_empty session
    form = URI.decode_www_form(only(fake.requests_to("POST", "/auth/token")).body).to_h

    assert_equal %w[authorization_code code_7QX2], form.values_at("grant_type", "code")
  end

  runs "partner-consent", "refuses_a_redirect_with_another_state" do
    context = SampleContext.new
    session = {}

    error = assert_raises(RuntimeError) do
      run_sample("partner-consent", FakeTransport.new, context:) do
        context.start_consent(session)
        context.finish_consent(session, code: "code_7QX2", state: "forged", org_id: ORG_ID)
      end
    end
    assert_match(/state mismatch/, error.message)
  end

  runs "partner-grant", "saves_the_rotated_refresh_token_before_listing" do
    context = SampleContext.new
    grants = GrantRows.new(ORG_ID => REFRESH_TOKEN_1)
    context.singleton_class.const_set(:OrganizationGrant, grants)
    fake = FakeTransport.new.on("POST", "/auth/token", grant_token_reply(ACCESS_TOKEN, REFRESH_TOKEN_2))
    fake.on("GET", LEARNERS_PATH, FakeTransport::Reply.json({ "items" => [LEARNER_JSON], "nextCursor" => nil }))

    assert_equal ["1"], run_sample("partner-grant", fake, context:)
    assert_equal({ ORG_ID => REFRESH_TOKEN_2 }, grants.rows)
    assert_equal REFRESH_TOKEN_1, URI.decode_www_form(fake.requests.first.body).to_h["refresh_token"]
  end

  runs "partner-organizations", "lists_customer_organizations_as_the_partner_app" do
    fake = FakeTransport.new.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    fake.on("GET", "/partners/ptn_01JD8E2C3D4E5F6G7H8J9K0M1N/organizations",
            FakeTransport::Reply.json({ "items" => [{ "orgId" => ORG_ID, "grantActive" => true }],
                                        "nextCursor" => nil }))

    assert_equal ["org_acme true"], run_sample("partner-organizations", fake)
    assert_equal "Basic #{APP_BASIC_CREDENTIALS}", fake.requests.first.headers["authorization"]
  end

  runs "events-tail", "resumes_from_the_saved_position_and_saves_each_event" do
    fake = sandbox_api
    events = [event_json("evt_01JD8B", "learner.started"), event_json("evt_01JD8C", "learner.certified")]
    fake.on("GET", "/organizations/#{ORG_ID}/events", FakeTransport::Reply.json({ "items" => events }))
    context = SampleContext.new

    output = run_sample("events-tail", fake, context:)

    assert_equal ["learner.started evt_01JD8B", "learner.certified evt_01JD8C"], output
    assert_equal %w[evt_01JD8B evt_01JD8C], context.cursor_store.saved
    assert_equal "evt_01JD8A", query(fake.requests_to("GET", "/organizations/#{ORG_ID}/events").first)["after"]
  end

  runs "configuration", "reads_back_the_frozen_settings" do
    output = run_sample("configuration", FakeTransport.new)

    assert_equal ["sandbox", SANDBOX_BASE, "3", "30.0", "true"], output
  end

  runs "logging", "logs_each_exchange_without_bodies" do
    fake = sandbox_api.on("GET", LEARNERS_PATH,
                          FakeTransport::Reply.json({ "items" => [LEARNER_JSON], "nextCursor" => nil },
                                                    headers: { "x-request-id" => REQUEST_ID }))
    stdout = StringIO.new

    run_sample("logging", fake, stdout:)

    assert_match(%r{teachmehipaa\.request method=GET path=/v1#{LEARNERS_PATH} status=200 .*request_id=#{REQUEST_ID}},
                 stdout.string)
    refute_includes stdout.string, "ana@example.com"
    refute_includes stdout.string, ACCESS_TOKEN
  end

  private

  # Runs sample +id+ with every client pointed at +fake+ and the README's
  # environment variables set, and returns what it printed. A block runs
  # after the sample, in the same setting, to call what the sample defined.
  def run_sample(id, fake, context: SampleContext.new, stdout: StringIO.new)
    sample = self.class.samples.find { |candidate| candidate.id == id } or flunk "no sample #{id}"
    saved_env = ENVIRONMENT.keys.to_h { |name| [name, ENV.fetch(name, nil)] }
    saved_stdout = $stdout
    begin
      ENV.update(ENVIRONMENT)
      $stdout = stdout
      Thread.current[:teachmehipaa_readme_transport] = fake
      context.instance_eval(sample.code, README, sample.line)
      yield if block_given?
    ensure
      Thread.current[:teachmehipaa_readme_transport] = nil
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

  def learner_reply
    FakeTransport::Reply.json(LEARNER_JSON.merge("learnerId" => SAMPLE_LEARNER_ID),
                              headers: { "etag" => ETAG, "x-request-id" => REQUEST_ID })
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

  # The monorepo's ExportArtifact for a two-row Learner export.
  def export_artifact
    csv = "email,status\r\nana@example.com,certified\r\nben@example.com,in_progress\r\n"
    { "format" => "csv", "contentType" => "text/csv", "filename" => "learners-org_acme.csv", "rowCount" => 2,
      "dataBase64" => [csv].pack("m0") }
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

  def event_json(event_id, event_type)
    { "eventId" => event_id, "eventType" => event_type, "orgId" => ORG_ID, "occurredAt" => "2026-11-15T12:00:00Z",
      "data" => { "learnerId" => SAMPLE_LEARNER_ID } }
  end

  def certified_event
    JSON.generate(event_json("evt_01JD8C", "learner.certified"))
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
