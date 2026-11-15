# frozen_string_literal: true

require_relative "test_helper"

# Updates as merge patches, and the write results of Learner create and
# upsert, through the public client.
class LearnerWritesTest < Minitest::Test
  include ClientHelpers

  ORG = "/organizations/#{Fixtures::ORG_ID}".freeze
  CREATE_PATH = "#{ORG}/learners".freeze
  UPSERT_PATH = "#{ORG}/learners/by-external-id/hr-123".freeze
  SUBSCRIPTION_ID = "whs_01JD8D"
  SUBSCRIPTION_PATH = "#{ORG}/webhook-subscriptions/#{SUBSCRIPTION_ID}".freeze
  MERGE_PATCH = "application/merge-patch+json"

  # dev#/components/schemas/LearnerCreated with delivery "none".
  CREATED_JSON = Fixtures::LEARNER_JSON.merge(
    "status" => "not_started", "startedAt" => nil, "delivery" => "none", "joinUrl" => "https://tme.so/j/7QX2",
  ).freeze

  # dev#/components/schemas/WebhookSubscriptionDto
  SUBSCRIPTION_JSON = {
    "subscriptionId" => SUBSCRIPTION_ID, "endpointUrl" => "https://hr.example.com/hooks/tmh",
    "eventTypes" => ["learner.certified"], "enabled" => true, "description" => nil, "seatsLowThreshold" => 5,
    "secretKeyId" => "whk_1", "createdAt" => "2026-11-01T09:00:00Z", "rev" => 4
  }.freeze

  def setup
    @transport = FakeTransport.new
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    @client = build_client(@transport, organization_id: ORG_ID)
  end

  def test_a_learner_update_leaves_unset_fields_out_and_sends_null_to_clear
    @transport.on("PATCH", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON.merge("externalId" => nil)))

    learner = @client.learners.update(LEARNER_ID, if_match: ETAG, external_id: nil)

    assert_nil learner.external_id
    request = only(@transport.requests_to("PATCH", LEARNER_PATH))

    assert_equal MERGE_PATCH, request.headers["content-type"]
    assert_equal '{"externalId":null}', request.body
  end

  def test_omit_passed_explicitly_leaves_the_field_unchanged
    @transport.on("PATCH", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))

    @client.learners.update(LEARNER_ID, if_match: ETAG, name: "Ana B. Lima", external_id: TeachMeHipaa::OMIT)

    assert_equal '{"name":"Ana B. Lima"}', only(@transport.requests_to("PATCH", LEARNER_PATH)).body
  end

  def test_a_learner_update_keeps_the_course_query_out_of_the_patch
    @transport.on("PATCH", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))

    @client.learners.update(LEARNER_ID, if_match: ETAG, name: "Ana B. Lima", course_id: "hipaa-2026")

    request = only(@transport.requests_to("PATCH", LEARNER_PATH))

    assert_equal "#{LIVE_BASE}#{LEARNER_PATH}?courseId=hipaa-2026", request.url
    assert_equal({ "name" => "Ana B. Lima" }, JSON.parse(request.body))
  end

  def test_a_subscription_update_sends_only_what_was_given
    @transport.on("PATCH", SUBSCRIPTION_PATH, FakeTransport::Reply.json(SUBSCRIPTION_JSON))

    @client.webhook_subscriptions.update(SUBSCRIPTION_ID, if_match: '"4"', description: nil,
                                                          event_types: %w[learner.certified seats.low])

    request = only(@transport.requests_to("PATCH", SUBSCRIPTION_PATH))

    assert_equal MERGE_PATCH, request.headers["content-type"]
    assert_equal({ "description" => nil, "eventTypes" => %w[learner.certified seats.low] }, JSON.parse(request.body))
  end

  def test_creating_a_learner_reports_created_with_its_delivery_details
    @transport.on("POST", CREATE_PATH,
                  FakeTransport::Reply.json(CREATED_JSON, status: 201, headers: { "etag" => ETAG }))

    result = @client.learners.create(email: "ana@example.com", delivery: "none")

    assert_predicate result, :created?
    assert_equal ["none", "https://tme.so/j/7QX2", ETAG], [result.delivery, result.join_url, result.last_response.etag]
    request = only(@transport.requests_to("POST", CREATE_PATH))

    assert_equal({ "email" => "ana@example.com", "delivery" => "none" }, JSON.parse(request.body))
    assert request.headers["idempotency-key"]
  end

  def test_a_learner_already_there_is_not_created_and_has_no_delivery_details
    @transport.on("POST", CREATE_PATH, FakeTransport::Reply.json(LEARNER_JSON))

    result = @client.learners.create(email: "ana@example.com")

    refute_predicate result, :created?
    assert_equal LEARNER_ID, result.learner_id
    assert_nil result.delivery
    assert_nil result.join_url
  end

  def test_a_replayed_upsert_is_told_apart_from_the_first
    @transport.on("PUT", UPSERT_PATH, FakeTransport::Reply.json(CREATED_JSON, status: 201))
    @transport.on("PUT", UPSERT_PATH, FakeTransport::Reply.json(LEARNER_JSON))

    first = @client.learners.upsert_by_external_id("hr-123", email: "ana@example.com", delivery: "none")
    replay = @client.learners.upsert_by_external_id("hr-123", email: "ana@example.com", delivery: "none")

    assert_equal [true, "https://tme.so/j/7QX2"], [first.created?, first.join_url]
    assert_equal [false, nil], [replay.created?, replay.join_url]
  end
end
