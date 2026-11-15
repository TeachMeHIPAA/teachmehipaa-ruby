# frozen_string_literal: true

require_relative "test_helper"

# Conditional writes (If-Match) and reads (If-None-Match), through the
# public client.
class ConditionalRequestsTest < Minitest::Test
  include ClientHelpers

  ORG = "/organizations/#{Fixtures::ORG_ID}".freeze
  OFFBOARD_PATH = "#{Fixtures::LEARNER_PATH}:offboard".freeze
  SUBSCRIPTION_ID = "whs_01JD8D"
  SUBSCRIPTION_PATH = "#{ORG}/webhook-subscriptions/#{SUBSCRIPTION_ID}".freeze
  # Learners carry a quoted SHA-256 hex strong tag (api-sdk-surface.md §5).
  LEARNER_ETAG = '"9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"'
  # Rev-based resources carry a quoted revision.
  COURSE_ETAG = '"7"'
  COURSE_ID = "hipaa-2026"
  COURSE_PATH = "/courses/#{COURSE_ID}".freeze
  # dev#/components/schemas/CourseDto
  COURSE_JSON = {
    "courseId" => COURSE_ID, "title" => "HIPAA Training 2026", "courseVersion" => "2026.1", "passingThreshold" => 80
  }.freeze

  # dev#/components/schemas/WebhookSubscriptionDto
  SUBSCRIPTION_JSON = {
    "subscriptionId" => SUBSCRIPTION_ID, "endpointUrl" => "https://hr.example.com/hooks/tmh",
    "eventTypes" => ["learner.certified"], "enabled" => false, "description" => nil, "seatsLowThreshold" => 5,
    "secretKeyId" => "whk_1", "createdAt" => "2026-11-01T09:00:00Z", "rev" => 4
  }.freeze

  def setup
    @transport = FakeTransport.new
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    @client = build_client(@transport, organization_id: ORG_ID)
  end

  def test_if_match_sends_the_etag_given_as_a_string
    @transport.on("PATCH", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON, headers: { "etag" => '"next"' }))

    learner = @client.learners.update(LEARNER_ID, if_match: LEARNER_ETAG, name: "Ana Example")

    assert_equal '"next"', learner.last_response.etag
    assert_equal LEARNER_ETAG, only(@transport.requests_to("PATCH", LEARNER_PATH)).headers["if-match"]
  end

  def test_if_match_takes_the_etag_from_a_learner_the_client_returned
    @transport.on("GET", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON, headers: { "etag" => LEARNER_ETAG }))
    @transport.on("PATCH", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))

    learner = @client.learners.retrieve(LEARNER_ID)
    @client.learners.update(LEARNER_ID, if_match: learner, external_id: nil)

    assert_equal LEARNER_ETAG, only(@transport.requests_to("PATCH", LEARNER_PATH)).headers["if-match"]
  end

  def test_an_object_without_an_etag_is_refused_before_sending
    @transport.on("GET", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))
    learner = @client.learners.retrieve(LEARNER_ID)

    error = assert_raises(ArgumentError) { @client.learners.offboard(LEARNER_ID, if_match: learner) }

    assert_match(/ETag/, error.message)
    assert_empty @transport.requests_to("POST", OFFBOARD_PATH)
  end

  def test_an_optional_if_match_is_left_out_when_not_given
    @transport.on("POST", OFFBOARD_PATH, FakeTransport::Reply.json(LEARNER_JSON))

    @client.learners.offboard(LEARNER_ID)

    refute only(@transport.requests_to("POST", OFFBOARD_PATH)).headers.key?("if-match")
  end

  def test_a_stale_etag_raises_precondition_failed_without_a_retry
    @transport.on("PATCH", LEARNER_PATH,
                  problem(412, "precondition_failed", title: "Precondition failed",
                                                      detail: "The resource has changed since you read it."))

    error = assert_raises(TeachMeHipaa::PreconditionFailedError) do
      @client.learners.update(LEARNER_ID, if_match: LEARNER_ETAG, name: "Ana Example")
    end

    assert_equal [412, "precondition_failed", REQUEST_ID], [error.status, error.code, error.request_id]
    assert_equal 1, @transport.requests_to("PATCH", LEARNER_PATH).length
  end

  def test_a_missing_precondition_raises_precondition_failed
    @transport.on("PATCH", SUBSCRIPTION_PATH,
                  problem(428, "precondition_required", title: "Precondition required",
                                                        detail: "Send If-Match with the resource's current ETag."))

    error = assert_raises(TeachMeHipaa::PreconditionFailedError) do
      @client.webhook_subscriptions.update(SUBSCRIPTION_ID, if_match: "*", enabled: false)
    end

    assert_equal [428, "precondition_required"], [error.status, error.code]
  end

  def test_if_match_takes_the_etag_from_a_returned_subscription
    @transport.on("GET", SUBSCRIPTION_PATH, FakeTransport::Reply.json(SUBSCRIPTION_JSON, headers: { "etag" => '"4"' }))
    @transport.on("PATCH", SUBSCRIPTION_PATH, FakeTransport::Reply.json(SUBSCRIPTION_JSON))

    subscription = @client.webhook_subscriptions.retrieve(SUBSCRIPTION_ID)
    @client.webhook_subscriptions.update(SUBSCRIPTION_ID, if_match: subscription, enabled: true)

    assert_equal '"4"', only(@transport.requests_to("PATCH", SUBSCRIPTION_PATH)).headers["if-match"]
  end

  def test_a_current_copy_comes_back_as_not_modified
    @transport.on("GET", COURSE_PATH, FakeTransport::Reply.new(
                                        status: 304, body: "", content_type: nil,
                                        headers: { "etag" => COURSE_ETAG, "x-request-id" => "req_304" }
                                      ))

    result = @client.courses.retrieve(COURSE_ID, if_none_match: COURSE_ETAG)

    assert_instance_of TeachMeHipaa::NotModified, result
    assert_predicate result, :not_modified?
    assert_equal [304, COURSE_ETAG, "req_304"],
                 [result.last_response.status, result.last_response.etag, result.last_response.request_id]
    assert_equal COURSE_ETAG, only(@transport.requests_to("GET", COURSE_PATH)).headers["if-none-match"]
  end

  def test_a_changed_object_is_returned_using_the_held_copys_etag
    @transport.on("GET", COURSE_PATH, FakeTransport::Reply.json(COURSE_JSON, headers: { "etag" => COURSE_ETAG }))
    @transport.on("GET", COURSE_PATH, FakeTransport::Reply.json(COURSE_JSON.merge("courseVersion" => "2026.2"),
                                                                headers: { "etag" => '"8"' }))
    cached = @client.courses.retrieve(COURSE_ID)

    result = @client.courses.retrieve(COURSE_ID, if_none_match: cached)
    current = result.not_modified? ? cached : result

    assert_equal "2026.2", current.course_version
    assert_equal COURSE_ETAG, @transport.requests_to("GET", COURSE_PATH).last.headers["if-none-match"]
  end

  def test_a_plain_retrieve_sends_no_if_none_match
    @transport.on("GET", COURSE_PATH, FakeTransport::Reply.json(COURSE_JSON))

    course = @client.courses.retrieve(COURSE_ID)

    refute_predicate course, :not_modified?
    refute only(@transport.requests_to("GET", COURSE_PATH)).headers.key?("if-none-match")
  end

  def test_every_retrieve_the_api_answers_conditionally_takes_if_none_match
    retrieves = [
      [@client.enrollments, "#{ORG}/enrollments/enr_1", "enr_1"],
      [@client.seat_orders, "#{ORG}/seat-orders/so_1", "so_1"],
      [@client.webhook_subscriptions, "#{ORG}/webhook-subscriptions/whs_1", "whs_1"],
    ]
    retrieves.each do |resource, path, id|
      @transport.on("GET", path, FakeTransport::Reply.new(status: 304, body: "", content_type: nil, headers: {}))

      assert_instance_of TeachMeHipaa::NotModified, resource.retrieve(id, if_none_match: '"3"')
      assert_equal '"3"', only(@transport.requests_to("GET", path)).headers["if-none-match"]
    end
  end
end
