# frozen_string_literal: true

require_relative "test_helper"

class UnauthorizedReplayTest < Minitest::Test
  include ClientHelpers

  REMIND_PATH = "#{Fixtures::LEARNER_PATH}:remind".freeze
  OK = FakeTransport::Reply.json(Fixtures::LEARNER_JSON)
  UNAUTHORIZED = Fixtures.problem(
    401, "unauthorized", title: "Unauthorized", headers: { "www-authenticate" => 'Bearer error="invalid_token"' }
  )

  def setup
    @transport = FakeTransport.new
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json(ACCESS_TOKEN)))
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json(SECOND_ACCESS_TOKEN)))
  end

  def test_a_revoked_token_is_re_minted_once_and_the_request_replayed
    script(UNAUTHORIZED, OK)

    learner = client.learners.retrieve(LEARNER_ID)

    assert_equal LEARNER_ID, learner.learner_id
    assert_equal 2, mints
    assert_equal ["Bearer #{ACCESS_TOKEN}", "Bearer #{SECOND_ACCESS_TOKEN}"], bearers("GET", LEARNER_PATH)
  end

  def test_the_replay_does_not_count_as_a_retry
    script(UNAUTHORIZED, OK)

    learner = client(max_retries: 0).learners.retrieve(LEARNER_ID)

    assert_equal LEARNER_ID, learner.learner_id
  end

  def test_retries_are_still_available_after_a_replay
    unavailable = Fixtures.problem(503, "temporarily_unavailable")
    script(UNAUTHORIZED, unavailable, unavailable, OK)

    client.learners.retrieve(LEARNER_ID)

    assert_equal 4, @transport.requests_to("GET", LEARNER_PATH).length
  end

  def test_a_second_401_raises_the_authentication_error
    script(UNAUTHORIZED)

    error = assert_raises(TeachMeHipaa::AuthenticationError) { client.learners.retrieve(LEARNER_ID) }

    assert_equal "unauthorized", error.code
    assert_equal 2, @transport.requests_to("GET", LEARNER_PATH).length
    assert_equal 2, mints
  end

  def test_a_replay_is_not_spent_twice_in_one_call
    script(UNAUTHORIZED, Fixtures.problem(503, "temporarily_unavailable"), UNAUTHORIZED, OK)

    assert_raises(TeachMeHipaa::AuthenticationError) { client.learners.retrieve(LEARNER_ID) }

    assert_equal 3, @transport.requests_to("GET", LEARNER_PATH).length
  end

  def test_a_401_with_another_code_is_not_replayed
    script(Fixtures.problem(401, "token_expired_in_future_api"), OK)

    assert_raises(TeachMeHipaa::AuthenticationError) { client.learners.retrieve(LEARNER_ID) }

    assert_equal 1, mints
  end

  def test_a_non_retry_safe_request_is_still_replayed
    @transport.on("PATCH", LEARNER_PATH, UNAUTHORIZED)
    @transport.on("PATCH", LEARNER_PATH, OK)

    client.learners.update(LEARNER_ID, if_match: ETAG, name: "Ana Souza")

    assert_equal ["Bearer #{ACCESS_TOKEN}", "Bearer #{SECOND_ACCESS_TOKEN}"], bearers("PATCH", LEARNER_PATH)
  end

  def test_a_replayed_write_keeps_its_idempotency_key
    @transport.on("POST", REMIND_PATH, UNAUTHORIZED)
    @transport.on("POST", REMIND_PATH,
                  FakeTransport::Reply.json({ "learnerId" => LEARNER_ID, "action" => "remind" }, status: 202))

    client(max_retries: 0).learners.remind(LEARNER_ID)

    first, replayed = @transport.requests_to("POST", REMIND_PATH)

    assert_equal first.headers["idempotency-key"], replayed.headers["idempotency-key"]
    assert_equal "Bearer #{SECOND_ACCESS_TOKEN}", replayed.headers["authorization"]
  end

  def test_concurrent_401s_re_mint_one_token
    revoked_first_token = lambda do |request|
      sleep 0.01 # keep every caller in flight with the first token
      request.headers["authorization"] == "Bearer #{ACCESS_TOKEN}" ? UNAUTHORIZED : OK
    end
    script(revoked_first_token)
    shared = client

    Array.new(5) { Thread.new { shared.learners.retrieve(LEARNER_ID) } }.each(&:join)

    assert_equal 2, mints
    assert_equal 10, @transport.requests_to("GET", LEARNER_PATH).length
  end

  private

  def client(**)
    build_client(@transport, organization_id: ORG_ID, sleep: FakeSleep.new, **)
  end

  def script(*replies)
    replies.each { |reply| @transport.on("GET", LEARNER_PATH, reply) }
  end

  def mints
    @transport.requests_to("POST", "/auth/token").length
  end

  def bearers(method, path)
    @transport.requests_to(method, path).map { |r| r.headers["authorization"] }
  end
end
