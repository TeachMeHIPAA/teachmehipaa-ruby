# frozen_string_literal: true

require_relative "test_helper"

class IdempotencyTest < Minitest::Test
  include ClientHelpers

  REMIND_PATH = "#{Fixtures::LEARNER_PATH}:remind".freeze
  LAUNCH_LINK_PATH = "#{Fixtures::LEARNER_PATH}:createLaunchLink".freeze
  REMIND_ACCEPTED = FakeTransport::Reply.json({ "learnerId" => Fixtures::LEARNER_ID, "action" => "remind" },
                                              status: 202)
  LAUNCH_LINK = FakeTransport::Reply.json(
    { "url" => "https://training.teachmehipaa.com/launch/abc123", "expiresAt" => "2026-11-15T12:05:00Z" },
    status: 201,
  )
  UNAVAILABLE = Fixtures.problem(503, "temporarily_unavailable")
  UUID_V4 = /\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z/

  def setup
    @transport = FakeTransport.new
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    @client = build_client(@transport, organization_id: ORG_ID, sleep: FakeSleep.new)
  end

  def test_a_call_that_requires_a_key_sends_a_generated_uuid_v4
    @transport.on("POST", REMIND_PATH, REMIND_ACCEPTED)

    accepted = @client.learners.remind(LEARNER_ID)

    assert_equal [LEARNER_ID, TeachMeHipaa::LearnerRemindAcceptedAction::REMIND],
                 [accepted.learner_id, accepted.action]
    assert_equal 202, accepted.last_response.status
    assert_match UUID_V4, only(keys_sent(REMIND_PATH))
  end

  def test_each_call_gets_a_new_key
    @transport.on("POST", REMIND_PATH, REMIND_ACCEPTED)

    2.times { @client.learners.remind(LEARNER_ID) }

    first, second = keys_sent(REMIND_PATH)

    refute_equal first, second
  end

  def test_retries_reuse_the_same_key
    @transport.on("POST", REMIND_PATH, UNAVAILABLE)
    @transport.on("POST", REMIND_PATH, Fixtures::NETWORK_ERROR)
    @transport.on("POST", REMIND_PATH, REMIND_ACCEPTED)

    @client.learners.remind(LEARNER_ID)

    keys = keys_sent(REMIND_PATH)

    assert_equal 3, keys.length
    assert_equal 1, keys.uniq.length
  end

  def test_an_in_flight_duplicate_is_retried_with_the_same_key
    @transport.on("POST", REMIND_PATH, Fixtures.problem(409, "conflict", detail: "Request already in flight"))
    @transport.on("POST", REMIND_PATH, REMIND_ACCEPTED)

    @client.learners.remind(LEARNER_ID)

    first, second = keys_sent(REMIND_PATH)

    assert_equal first, second
  end

  def test_a_caller_supplied_key_is_sent_as_is
    @transport.on("POST", REMIND_PATH, UNAVAILABLE)
    @transport.on("POST", REMIND_PATH, REMIND_ACCEPTED)

    @client.learners.remind(LEARNER_ID, request_options: { idempotency_key: "sync-2026-11-15-42" })

    assert_equal ["sync-2026-11-15-42"] * 2, keys_sent(REMIND_PATH)
  end

  def test_reusing_a_key_with_another_body_raises_the_idempotency_error
    @transport.on("POST", REMIND_PATH, Fixtures.problem(422, "idempotency_key_reuse"))

    assert_raises(TeachMeHipaa::IdempotencyError) do
      @client.learners.remind(LEARNER_ID, request_options: { idempotency_key: "reused" })
    end

    assert_equal 1, keys_sent(REMIND_PATH).length
  end

  def test_a_get_sends_no_idempotency_key
    @transport.on("GET", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))

    @client.learners.retrieve(LEARNER_ID)

    refute only(@transport.requests_to("GET", LEARNER_PATH)).headers.key?("idempotency-key")
  end

  def test_a_launch_link_is_retried_without_a_key
    @transport.on("POST", LAUNCH_LINK_PATH, UNAVAILABLE)
    @transport.on("POST", LAUNCH_LINK_PATH, LAUNCH_LINK)

    link = @client.learners.create_launch_link(LEARNER_ID)

    assert_equal "https://training.teachmehipaa.com/launch/abc123", link.url
    assert_equal Time.utc(2026, 11, 15, 12, 5), link.expires_at
    assert_equal [nil, nil], keys_sent(LAUNCH_LINK_PATH)
  end

  def test_a_body_less_custom_method_sends_no_content_type
    @transport.on("POST", REMIND_PATH, REMIND_ACCEPTED)

    @client.learners.remind(LEARNER_ID, course_id: "hipaa-advanced")

    request = only(@transport.requests_to("POST", REMIND_PATH))

    assert_nil request.body
    refute request.headers.key?("content-type")
    assert_equal "courseId=hipaa-advanced", URI(request.url).query
  end

  def test_a_patch_sends_a_json_merge_patch_and_is_not_retried
    @transport.on("PATCH", LEARNER_PATH, UNAVAILABLE)
    @transport.on("PATCH", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))

    assert_raises(TeachMeHipaa::APIError) { @client.learners.update(LEARNER_ID, if_match: ETAG, name: "Ana Souza") }

    request = only(@transport.requests_to("PATCH", LEARNER_PATH))

    refute request.headers.key?("idempotency-key")
    assert_equal ETAG, request.headers["if-match"]
    assert_equal "application/merge-patch+json", request.headers["content-type"]
    assert_equal({ "name" => "Ana Souza" }, JSON.parse(request.body))
  end

  def test_a_patch_is_not_retried_after_a_network_error
    @transport.on("PATCH", LEARNER_PATH, Fixtures::NETWORK_ERROR)

    assert_raises(TeachMeHipaa::APIConnectionError) do
      @client.learners.update(LEARNER_ID, if_match: ETAG, name: "Ana Souza")
    end

    assert_equal 1, @transport.requests_to("PATCH", LEARNER_PATH).length
  end

  def test_a_patch_with_a_caller_supplied_key_is_still_not_retried
    @transport.on("PATCH", LEARNER_PATH, UNAVAILABLE)

    assert_raises(TeachMeHipaa::APIError) do
      @client.learners.update(LEARNER_ID, if_match: ETAG, name: "Ana Souza",
                                          request_options: { idempotency_key: "patch-1" })
    end

    keys = @transport.requests_to("PATCH", LEARNER_PATH).map { |r| r.headers["idempotency-key"] }

    assert_equal ["patch-1"], keys
  end

  def test_a_successful_patch_returns_the_updated_learner
    @transport.on("PATCH", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON.merge("name" => "Ana Souza")))

    learner = @client.learners.update(LEARNER_ID, if_match: ETAG, name: "Ana Souza")

    assert_equal "Ana Souza", learner.name
  end

  private

  def keys_sent(path)
    @transport.requests_to("POST", path).map { |r| r.headers["idempotency-key"] }
  end
end
