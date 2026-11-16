# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "teachmehipaa"
require "minitest/autorun"
require "action_controller"
require "active_job"
require "rack/mock"
require "logger"
require "stringio"
require_relative "../support/fixtures"
require_relative "../support/fake_transport"
require_relative "../support/sample_transport"
require_relative "../support/doc_samples"

# What the Rails guide's samples read from Rails: credentials, the
# environment and the logger. Action Pack and Active Job are the real gems;
# only this module stands in for a booted app.
module Rails
  CREDENTIALS = {
    teachmehipaa: {
      client_id: Fixtures::CLIENT_ID,
      client_secret: Fixtures::CLIENT_SECRET,
      webhook_secret: "whsec_rails-guide-secret",
    },
  }.freeze
  Application = Data.define(:credentials)
  LOG = StringIO.new

  def self.application = @application || Application.new(credentials: CREDENTIALS)

  # Swaps in other credentials for the block, as another environment's
  # credentials file would.
  def self.with_credentials(credentials)
    @application = Application.new(credentials:)
    yield
  ensure
    @application = nil
  end

  def self.env = ActiveSupport::EnvironmentInquirer.new("development")
  def self.logger = @logger ||= Logger.new(LOG)
end

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = Logger.new(nil)

class ApplicationJob < ActiveJob::Base; end

# The job the webhook controller enqueues for a certified Learner.
class CertifiedLearnerJob < ApplicationJob
  def perform(learner_id); end
end

# The app the guide's initializer, job and controller are loaded into, in
# the order a Rails app boots them, so each finds the constants the earlier
# ones define.
module RailsApp
  %w[rails/initializer rails/job rails/webhook-controller].each do |id|
    sample = DocSamples.find(id) or raise "no sample #{id} in docs/guides/rails.md"
    module_eval(sample.code, sample.file, sample.line)
  end
end

# Runs the Rails guide's samples against Action Pack and Active Job, apart
# from the main suite so that loading Rails can't change what the unit tests
# see. test/readme_test.rb's RAILS_SUITE lists the samples this file runs.
class RailsGuideTest < Minitest::Test
  include Fixtures
  include ActiveJob::TestHelper

  ORG_ID = Fixtures::ORG_ID
  WEBHOOK_PATH = "/webhooks/teachmehipaa"

  def test_the_initializer_builds_a_sandbox_client_that_logs_to_rails_logger
    client = RailsApp::TEACHMEHIPAA
    fake = sandbox_api.on("GET", "/organizations/#{ORG_ID}/compliance",
                          FakeTransport::Reply.json({ "compliantRate" => 0.9 }))

    assert_equal :sandbox, client.environment
    assert_same Rails.logger, client.config.logger
    assert_in_delta(0.9, SampleTransport.using(fake) { client.compliance.retrieve.compliant_rate })
    assert_includes Rails::LOG.string, "teachmehipaa.request method=GET"
  end

  def test_the_initializer_boots_without_credentials_and_refuses_half_a_pair
    without = credentials_module(client_id: nil, client_secret: nil)

    assert_equal :sandbox, without::TEACHMEHIPAA.environment
    assert_raises(ArgumentError) { credentials_module(client_id: CLIENT_ID, client_secret: nil) }
  end

  def test_the_job_upserts_the_learner_by_external_id
    path = "/organizations/#{ORG_ID}/learners/by-external-id/hr-1042"
    fake = sandbox_api.on("PUT", path, FakeTransport::Reply.json(learner_json(created: true), status: 201))

    SampleTransport.using(fake) do
      RailsApp::EnrollEmployeeJob.perform_now("hr-1042", "dana.whitfield@example.com", "Dana Whitfield")
    end

    assert_equal({ "email" => "dana.whitfield@example.com", "name" => "Dana Whitfield" },
                 JSON.parse(fake.requests_to("PUT", path).first.body))
    assert_includes Rails::LOG.string, "TeachMeHIPAA Learner sub_dana invited"
  end

  def test_the_job_reschedules_itself_a_minute_after_a_rate_limit
    path = "/organizations/#{ORG_ID}/learners/by-external-id/hr-1042"
    # Retry-After: 0 keeps the client's own retries from waiting.
    limited = FakeTransport::Reply.json({ "status" => 429, "code" => "rate_limited" },
                                        status: 429, headers: { "retry-after" => "0" },
                                        content_type: "application/problem+json")
    fake = sandbox_api.on("PUT", path, limited)
    started = Time.now

    SampleTransport.using(fake) do
      RailsApp::EnrollEmployeeJob.perform_now("hr-1042", "dana.whitfield@example.com", "Dana Whitfield")
    end

    job = enqueued_jobs.last

    assert_equal 3, fake.requests_to("PUT", path).length
    assert_equal RailsApp::EnrollEmployeeJob, job.fetch(:job)
    assert_operator job.fetch(:at), :>=, started.to_f + 59
  end

  def test_the_controller_accepts_a_signed_delivery_and_enqueues_a_job
    payload = JSON.generate("eventId" => "evt_01JD8C", "eventType" => "learner.certified", "orgId" => ORG_ID,
                            "occurredAt" => "2026-11-15T12:00:00Z", "data" => { "learnerId" => "sub_dana" })
    path = "#{WEBHOOK_PATH}?source=hr"

    response = deliver(payload, path, signed_for: path)

    assert_equal [200, ""], [response.status, response.body]
    assert_enqueued_with(job: CertifiedLearnerJob, args: ["sub_dana"])
  end

  def test_the_controller_answers_a_test_delivery_with_ok
    payload = JSON.generate("test" => true, "subscriptionId" => "whs_01JD8D")

    assert_equal 200, deliver(payload, WEBHOOK_PATH, signed_for: WEBHOOK_PATH).status
    assert_no_enqueued_jobs
  end

  def test_the_controller_rejects_a_delivery_signed_for_another_path_as_a_bad_request
    payload = JSON.generate("test" => true, "subscriptionId" => "whs_01JD8D")

    response = deliver(payload, "#{WEBHOOK_PATH}?source=hr", signed_for: WEBHOOK_PATH)

    assert_equal [400, "signature_mismatch"], [response.status, response.body]
  end

  private

  def sandbox_api
    FakeTransport.new(SANDBOX_BASE)
                 .on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
                 .on("GET", "/auth/introspection", FakeTransport::Reply.json(introspection_json))
  end

  def learner_json(created:)
    { "learnerId" => "sub_dana", "email" => "dana.whitfield@example.com", "name" => "Dana Whitfield",
      "externalId" => "hr-1042", "status" => "not_started", "created" => created }
  end

  # The initializer, loaded into a fresh module with other credentials.
  def credentials_module(client_id:, client_secret:)
    sample = DocSamples.find("rails/initializer")
    Rails.with_credentials({ teachmehipaa: { client_id:, client_secret: } }) do
      Module.new.tap { |namespace| namespace.module_eval(sample.code, sample.file, sample.line) }
    end
  end

  # POSTs +payload+ to the controller on +path+, signed as TeachMeHIPAA
  # would sign it for +signed_for+, the way a Rack server hands it over.
  def deliver(payload, path, signed_for:)
    secret = Rails.application.credentials.dig(:teachmehipaa, :webhook_secret)
    headers = TeachMeHipaa::Webhook.generate_test_headers(payload:, secret:, path: signed_for)
    env = headers.to_h { |name, value| ["HTTP_#{name.upcase.tr("-", "_")}", value] }
    env["CONTENT_TYPE"] = env.delete("HTTP_CONTENT_TYPE")
    app = RailsApp::TeachmehipaaWebhooksController.action(:create)
    Rack::MockRequest.new(app).post("http://localhost#{path}", env.merge(input: payload))
  end
end
