# frozen_string_literal: true

require_relative "test_helper"

class RetriesTest < Minitest::Test
  include ClientHelpers

  OK = FakeTransport::Reply.json(Fixtures::LEARNER_JSON)
  UNAVAILABLE = Fixtures.problem(503, "temporarily_unavailable")

  def setup
    @transport = FakeTransport.new
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    @sleep = FakeSleep.new
  end

  {
    "500" => Fixtures.problem(500, "internal"),
    "502" => Fixtures.problem(502, "refund_failed"),
    "503" => Fixtures.problem(503, "temporarily_unavailable"),
    "429" => Fixtures.problem(429, "rate_limited"),
    "409_conflict" => Fixtures.problem(409, "conflict"),
    "network_error" => Fixtures::NETWORK_ERROR,
    "timeout" => Fixtures::READ_TIMEOUT,
  }.each do |name, transient|
    define_method("test_a_get_is_retried_after_#{name}") do
      script(transient, OK)

      learner = client.learners.retrieve(LEARNER_ID)

      assert_equal LEARNER_ID, learner.learner_id
      assert_equal 2, attempts
      assert_equal 1, @sleep.waits.length
    end
  end

  {
    "400" => Fixtures.problem(400, "validation_failed"),
    "404" => Fixtures.problem(404, "not_found"),
    "409_seat_unavailable" => Fixtures.problem(409, "seat_unavailable"),
    "412" => Fixtures.problem(412, "precondition_failed"),
    "422" => Fixtures.problem(422, "validation_failed"),
  }.each do |name, permanent|
    define_method("test_a_get_is_not_retried_after_#{name}") do
      script(permanent, OK)

      assert_raises(TeachMeHipaa::Error) { client.learners.retrieve(LEARNER_ID) }

      assert_equal 1, attempts
      assert_empty @sleep.waits
    end
  end

  def test_retries_twice_by_default_then_raises_the_last_error
    script(UNAVAILABLE)

    error = assert_raises(TeachMeHipaa::APIError) { client.learners.retrieve(LEARNER_ID) }

    assert_equal 503, error.status
    assert_equal 3, attempts
    assert_equal 2, @sleep.waits.length
  end

  def test_backoff_starts_at_half_a_second_and_doubles_to_a_5_second_cap
    script(UNAVAILABLE)

    assert_raises(TeachMeHipaa::APIError) { client(max_retries: 6).learners.retrieve(LEARNER_ID) }

    # Jitter shortens each nominal delay by at most half, never below 0.5 s.
    nominal = [0.5, 1.0, 2.0, 4.0, 5.0, 5.0]

    assert_equal nominal.length, @sleep.waits.length
    @sleep.waits.zip(nominal).each do |waited, delay|
      assert_operator waited, :>=, [0.5, delay / 2].max
      assert_operator waited, :<=, delay
    end
  end

  def test_jitter_spreads_the_waits_of_repeated_calls
    script(UNAVAILABLE)
    retrying = client(max_retries: 3)

    10.times { assert_raises(TeachMeHipaa::APIError) { retrying.learners.retrieve(LEARNER_ID) } }

    third_waits = @sleep.waits.each_slice(3).map(&:last)

    assert_operator third_waits.uniq.length, :>, 1
  end

  def test_retry_after_is_honored
    script(Fixtures.problem(429, "rate_limited", headers: { "retry-after" => "7" }), OK)

    client.learners.retrieve(LEARNER_ID)

    assert_equal [7.0], @sleep.waits
  end

  def test_retry_after_is_capped_at_60_seconds
    script(Fixtures.problem(429, "rate_limited", headers: { "retry-after" => "3600" }), OK)

    client.learners.retrieve(LEARNER_ID)

    assert_equal [60.0], @sleep.waits
  end

  def test_a_retry_after_on_a_503_is_honored_too
    script(Fixtures.problem(503, "temporarily_unavailable", headers: { "retry-after" => "2" }), OK)

    client.learners.retrieve(LEARNER_ID)

    assert_equal [2.0], @sleep.waits
  end

  def test_an_http_date_retry_after_falls_back_to_backoff
    script(Fixtures.problem(429, "rate_limited", headers: { "retry-after" => "Sun, 15 Nov 2026 18:00:00 GMT" }), OK)

    client.learners.retrieve(LEARNER_ID)

    assert_operator @sleep.waits.first, :<=, 0.5
  end

  def test_exhausted_retries_raise_the_rate_limit_error
    script(Fixtures.problem(429, "rate_limited"))

    assert_raises(TeachMeHipaa::RateLimitError) { client.learners.retrieve(LEARNER_ID) }
  end

  def test_exhausted_retries_after_network_errors_raise_a_connection_error
    script(Fixtures::NETWORK_ERROR)

    error = assert_raises(TeachMeHipaa::APIConnectionError) { client.learners.retrieve(LEARNER_ID) }

    assert_instance_of Errno::ECONNREFUSED, error.cause
    assert_equal 3, attempts
  end

  def test_a_conflict_error_still_exposes_its_code_after_retries
    script(Fixtures.problem(409, "conflict"))

    error = assert_raises(TeachMeHipaa::ConflictError) { client.learners.retrieve(LEARNER_ID) }

    assert_equal "conflict", error.code
    assert_equal 3, attempts
  end

  def test_max_retries_zero_on_the_client_disables_retries
    script(UNAVAILABLE, OK)

    assert_raises(TeachMeHipaa::APIError) { client(max_retries: 0).learners.retrieve(LEARNER_ID) }

    assert_equal 1, attempts
  end

  def test_max_retries_per_request_overrides_the_client
    script(UNAVAILABLE)

    assert_raises(TeachMeHipaa::APIError) do
      client(max_retries: 0).learners.retrieve(LEARNER_ID, request_options: { max_retries: 4 })
    end

    assert_equal 5, attempts
  end

  def test_a_negative_per_request_max_retries_is_rejected
    error = assert_raises(ArgumentError) do
      client.learners.retrieve(LEARNER_ID, request_options: { max_retries: -1 })
    end

    assert_match(/max_retries/, error.message)
    assert_equal 0, attempts
  end

  def test_a_non_positive_per_request_timeout_is_rejected
    assert_raises(ArgumentError) { client.learners.retrieve(LEARNER_ID, request_options: { timeout: 0 }) }
  end

  def test_the_default_timeout_is_80_seconds
    script(OK)
    retrying = client

    retrying.learners.retrieve(LEARNER_ID)

    assert_in_delta 80.0, retrying.timeout
    assert_equal [80.0, 80.0], @transport.requests.map(&:timeout)
  end

  def test_timeout_per_request_overrides_the_client_on_every_attempt
    script(UNAVAILABLE, OK)

    client(timeout: 30).learners.retrieve(LEARNER_ID, request_options: { timeout: 5 })

    assert_equal [5.0, 5.0], @transport.requests_to("GET", LEARNER_PATH).map(&:timeout)
  end

  def test_a_client_credentials_mint_is_retried
    transport = FakeTransport.new
    transport.on("POST", "/auth/token", FakeTransport::Reply.json(
                                          { "error" => "slow_down", "error_description" => "Slow down." },
                                          status: 429, headers: { "retry-after" => "3" },
                                        ))
    transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    transport.on("GET", LEARNER_PATH, OK)

    build_client(transport, organization_id: ORG_ID, sleep: @sleep).learners.retrieve(LEARNER_ID)

    assert_equal 2, transport.requests_to("POST", "/auth/token").length
    assert_equal [3.0], @sleep.waits
  end

  def test_a_mint_that_keeps_failing_is_not_retried_again_by_the_request
    transport = FakeTransport.new
    transport.on("POST", "/auth/token", Fixtures::NETWORK_ERROR)

    assert_raises(TeachMeHipaa::APIConnectionError) do
      build_client(transport, organization_id: ORG_ID, sleep: @sleep).learners.retrieve(LEARNER_ID)
    end

    assert_equal 3, transport.requests_to("POST", "/auth/token").length
    assert_empty transport.requests_to("GET", LEARNER_PATH)
  end

  def test_a_rejected_client_credential_is_not_retried
    transport = FakeTransport.new
    transport.on("POST", "/auth/token", FakeTransport::Reply.json({ "error" => "invalid_client" }, status: 401))

    assert_raises(TeachMeHipaa::OAuthError) do
      build_client(transport, organization_id: ORG_ID, sleep: @sleep).learners.retrieve(LEARNER_ID)
    end

    assert_equal 1, transport.requests_to("POST", "/auth/token").length
    assert_empty @sleep.waits
  end

  def test_organization_discovery_is_retried
    @transport.on("GET", "/auth/introspection", UNAVAILABLE)
    @transport.on("GET", "/auth/introspection", FakeTransport::Reply.json(introspection_json))
    script(OK)

    build_client(@transport, sleep: @sleep).learners.retrieve(LEARNER_ID)

    assert_equal 2, @transport.requests_to("GET", "/auth/introspection").length
  end

  private

  def client(**)
    build_client(@transport, organization_id: ORG_ID, sleep: @sleep, **)
  end

  def script(*replies)
    replies.each { |reply| @transport.on("GET", LEARNER_PATH, reply) }
  end

  def attempts
    @transport.requests_to("GET", LEARNER_PATH).length
  end
end
