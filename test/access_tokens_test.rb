# frozen_string_literal: true

require_relative "test_helper"

class AccessTokensTest < Minitest::Test
  include ClientHelpers

  def setup
    @transport = scripted_transport
  end

  def test_mints_a_token_with_http_basic_client_credentials
    build_client(@transport).learners.retrieve(LEARNER_ID)

    mint = only(@transport.requests_to("POST", "/auth/token"))

    assert_equal "Basic #{BASIC_CREDENTIALS}", mint.headers["authorization"]
    assert_equal "application/x-www-form-urlencoded", mint.headers["content-type"]
    assert_equal [%w[grant_type client_credentials]], URI.decode_www_form(mint.body)
  end

  def test_requests_only_the_scopes_given
    build_client(@transport, scopes: %w[learners:read compliance:read]).learners.retrieve(LEARNER_ID)

    mint = only(@transport.requests_to("POST", "/auth/token"))

    assert_equal [%w[grant_type client_credentials], ["scope", "learners:read compliance:read"]],
                 URI.decode_www_form(mint.body)
  end

  def test_reuses_a_cached_token_across_calls
    client = build_client(@transport)

    client.learners.retrieve(LEARNER_ID)
    client.learners.retrieve(LEARNER_ID)

    assert_equal 1, @transport.requests_to("POST", "/auth/token").length
    assert_equal ["Bearer #{ACCESS_TOKEN}"] * 2, bearer_tokens_sent
  end

  def test_re_mints_a_token_60_seconds_before_it_expires
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json(SECOND_ACCESS_TOKEN)))
    clock = FakeClock.new
    client = build_client(@transport, organization_id: ORG_ID, clock:)

    client.learners.retrieve(LEARNER_ID)
    clock.advance(839) # expires_in is 900, so 61 s of life are left
    client.learners.retrieve(LEARNER_ID)
    clock.advance(1) # 60 s left: renew now
    client.learners.retrieve(LEARNER_ID)

    assert_equal 2, @transport.requests_to("POST", "/auth/token").length
    assert_equal ["Bearer #{ACCESS_TOKEN}", "Bearer #{ACCESS_TOKEN}", "Bearer #{SECOND_ACCESS_TOKEN}"],
                 bearer_tokens_sent
  end

  def test_concurrent_calls_mint_exactly_one_token
    transport = FakeTransport.new
    gate = Gate.new
    transport.on("POST", "/auth/token", lambda { |_request|
      gate.arrive
      FakeTransport::Reply.json(token_json)
    })
    transport.on("GET", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))
    client = build_client(transport, organization_id: ORG_ID)

    callers = Array.new(5) { Thread.new { client.learners.retrieve(LEARNER_ID) } }
    callers.each(&:join)

    assert_equal 1, transport.requests_to("POST", "/auth/token").length
    assert_equal 5, transport.requests_to("GET", LEARNER_PATH).length
  end

  def test_a_rejected_credential_raises_with_the_oauth_error
    transport = FakeTransport.new
    transport.on("POST", "/auth/token", FakeTransport::Reply.json(
                                          { "error" => "invalid_client", "error_description" => "Unknown client." },
                                          status: 401, headers: { "x-request-id" => "req_auth" },
                                        ))
    client = TeachMeHipaa::Client.new(client_id: CLIENT_ID, client_secret: "tmh_cs_wrong", transport:)

    error = assert_raises(TeachMeHipaa::OAuthError) { client.learners.retrieve(LEARNER_ID) }

    assert_equal 401, error.status
    assert_equal "invalid_client", error.code
    assert_equal "Unknown client.", error.detail
    assert_equal "req_auth", error.request_id
    assert_empty transport.requests_to("GET", LEARNER_PATH)
  end

  private

  def bearer_tokens_sent
    @transport.requests_to("GET", LEARNER_PATH).map { |r| r.headers["authorization"] }
  end

  # Holds the first caller inside the token endpoint until every other
  # caller has had time to pile up behind it, so a missing single-flight
  # guard shows up as extra mints rather than passing by luck.
  class Gate
    def initialize
      @first = true
      @lock = Mutex.new
    end

    def arrive
      first = @lock.synchronize { @first.tap { @first = false } }
      sleep 0.05 if first
    end
  end
end
