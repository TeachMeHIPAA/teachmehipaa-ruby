# frozen_string_literal: true

require_relative "test_helper"

class PartnerGrantsTest < Minitest::Test
  include ClientHelpers

  TOKEN_PATH = "/auth/token"
  OK = FakeTransport::Reply.json(Fixtures::LEARNER_JSON)

  # A token store that records, at each save, which requests the API had
  # already seen, so ordering is asserted on the wire.
  class MemoryStore
    attr_reader :saved, :requests_seen_at_save

    def initialize(transport, initial = Fixtures::REFRESH_TOKEN_1)
      @transport = transport
      @initial = initial
      @saved = []
      @requests_seen_at_save = []
    end

    def load
      @saved.last || @initial
    end

    def save(refresh_token)
      @requests_seen_at_save << @transport.requests.map { |r| URI(r.url).path }
      @saved << refresh_token
    end
  end

  # Saves fail for the first +failures+ calls.
  class ReadOnlyStore
    attr_reader :attempted

    def initialize(failures: 1)
      @failures = failures
      @attempted = []
    end

    def load
      Fixtures::REFRESH_TOKEN_1
    end

    def save(refresh_token)
      @attempted << refresh_token
      raise IOError, "database is read-only" if @attempted.length <= @failures
    end
  end

  def setup
    @transport = FakeTransport.new
  end

  def test_the_rotated_refresh_token_is_saved_before_the_api_request_is_sent
    @transport.on("POST", TOKEN_PATH, grant_token_reply("jwt-org", REFRESH_TOKEN_2))
    @transport.on("GET", LEARNER_PATH, OK)
    store = MemoryStore.new(@transport)

    grant_client(store).learners.retrieve(LEARNER_ID)

    assert_equal [REFRESH_TOKEN_2], store.saved
    assert_equal [["/v1/auth/token"]], store.requests_seen_at_save
    exchange = only(@transport.requests_to("POST", TOKEN_PATH))

    assert_equal "Basic #{APP_BASIC_CREDENTIALS}", exchange.headers["authorization"]
    assert_equal({ "grant_type" => "refresh_token", "refresh_token" => REFRESH_TOKEN_1 }, form_of(exchange))
    assert_equal ["Bearer jwt-org"], bearers
  end

  def test_a_failed_save_aborts_the_call_without_using_the_access_token
    @transport.on("POST", TOKEN_PATH, grant_token_reply("jwt-org", REFRESH_TOKEN_2))

    error = assert_raises(TeachMeHipaa::TokenStoreError) do
      grant_client(ReadOnlyStore.new).learners.retrieve(LEARNER_ID)
    end

    assert_match(/token_store\.save failed/, error.message)
    assert_instance_of IOError, error.cause
    refute_includes error.message, REFRESH_TOKEN_2
    refute_includes error.message, "jwt-org"
    assert_empty @transport.requests_to("GET", LEARNER_PATH)
  end

  def test_after_a_failed_save_the_rotated_refresh_token_is_presented
    @transport.on("POST", TOKEN_PATH, grant_token_reply("jwt-1", REFRESH_TOKEN_2))
    @transport.on("POST", TOKEN_PATH, grant_token_reply("jwt-2", REFRESH_TOKEN_3))
    @transport.on("GET", LEARNER_PATH, OK)
    store = ReadOnlyStore.new(failures: 1)
    client = grant_client(store)

    assert_raises(TeachMeHipaa::TokenStoreError) { client.learners.retrieve(LEARNER_ID) }
    client.learners.retrieve(LEARNER_ID)

    assert_equal [REFRESH_TOKEN_1, REFRESH_TOKEN_2], refresh_tokens_sent
    assert_equal [REFRESH_TOKEN_2, REFRESH_TOKEN_3], store.attempted
  end

  def test_a_network_error_during_refresh_makes_exactly_one_exchange_attempt
    @transport.on("POST", TOKEN_PATH, NETWORK_ERROR)
    store = MemoryStore.new(@transport)

    error = assert_raises(TeachMeHipaa::APIConnectionError) { grant_client(store).learners.retrieve(LEARNER_ID) }

    assert_match(/not retried/, error.message)
    assert_match(/re-run consent/, error.message)
    assert_instance_of Errno::ECONNREFUSED, error.cause
    assert_equal 1, @transport.requests_to("POST", TOKEN_PATH).length
    assert_empty store.saved
  end

  def test_a_server_error_during_refresh_is_not_retried
    @transport.on("POST", TOKEN_PATH, oauth_error_reply("temporarily_unavailable", "Try later", status: 503))

    assert_raises(TeachMeHipaa::OAuthError) do
      grant_client(MemoryStore.new(@transport)).learners.retrieve(LEARNER_ID)
    end

    assert_equal 1, @transport.requests_to("POST", TOKEN_PATH).length
  end

  def test_invalid_grant_says_the_grant_was_revoked_or_its_token_reused
    @transport.on("POST", TOKEN_PATH, oauth_error_reply("invalid_grant", "Refresh token is invalid"))

    error = assert_raises(TeachMeHipaa::OAuthError) do
      grant_client(MemoryStore.new(@transport)).learners.retrieve(LEARNER_ID)
    end

    assert_equal "invalid_grant", error.code
    assert_equal 400, error.status
    assert_match(/revoked/, error.message)
    assert_match(/reused/, error.message)
    assert_match(/Re-run consent/, error.message)
    assert_equal 1, @transport.requests_to("POST", TOKEN_PATH).length
  end

  def test_concurrent_calls_exchange_the_refresh_token_once
    exchanges = Queue.new
    slow_token_endpoint = lambda do |_request|
      exchanges << :exchange
      sleep 0.02 # hold the exchange open while the other callers arrive
      grant_token_reply("jwt-org", REFRESH_TOKEN_2)
    end
    @transport.on("POST", TOKEN_PATH, slow_token_endpoint)
    @transport.on("GET", LEARNER_PATH, OK)
    store = MemoryStore.new(@transport)
    client = grant_client(store)

    Array.new(5) { Thread.new { client.learners.retrieve(LEARNER_ID) } }.each(&:join)

    assert_equal 1, exchanges.size
    assert_equal [REFRESH_TOKEN_2], store.saved
    assert_equal ["Bearer jwt-org"] * 5, bearers
  end

  def test_re_mints_60_seconds_before_expiry_with_the_rotated_refresh_token
    clock = FakeClock.new
    @transport.on("POST", TOKEN_PATH, grant_token_reply("jwt-1", REFRESH_TOKEN_2, expires_in: 900))
    @transport.on("POST", TOKEN_PATH, grant_token_reply("jwt-2", REFRESH_TOKEN_3, expires_in: 900))
    @transport.on("GET", LEARNER_PATH, OK)
    store = MemoryStore.new(@transport)
    client = grant_client(store, clock:)

    client.learners.retrieve(LEARNER_ID)
    clock.advance(839) # expires_in 900, so still 61 s of life left
    client.learners.retrieve(LEARNER_ID)
    clock.advance(1) # 60 s left: renew now
    client.learners.retrieve(LEARNER_ID)

    assert_equal [REFRESH_TOKEN_1, REFRESH_TOKEN_2], refresh_tokens_sent
    assert_equal [REFRESH_TOKEN_2, REFRESH_TOKEN_3], store.saved
    assert_equal ["Bearer jwt-1", "Bearer jwt-1", "Bearer jwt-2"], bearers
  end

  def test_a_401_re_mints_once_and_replays_the_request
    @transport.on("POST", TOKEN_PATH, grant_token_reply("jwt-1", REFRESH_TOKEN_2))
    @transport.on("POST", TOKEN_PATH, grant_token_reply("jwt-2", REFRESH_TOKEN_3))
    @transport.on("GET", LEARNER_PATH, Fixtures.problem(401, "unauthorized"))
    @transport.on("GET", LEARNER_PATH, OK)

    grant_client(MemoryStore.new(@transport)).learners.retrieve(LEARNER_ID)

    assert_equal [REFRESH_TOKEN_1, REFRESH_TOKEN_2], refresh_tokens_sent
    assert_equal ["Bearer jwt-1", "Bearer jwt-2"], bearers
  end

  def test_a_refresh_token_passed_up_front_is_used_for_the_first_exchange
    @transport.on("POST", TOKEN_PATH, grant_token_reply("jwt-org", REFRESH_TOKEN_3))
    @transport.on("GET", LEARNER_PATH, OK)
    store = MemoryStore.new(@transport, "tmh_rt_never_loaded")

    grant_client(store, refresh_token: REFRESH_TOKEN_2).learners.retrieve(LEARNER_ID)

    assert_equal [REFRESH_TOKEN_2], refresh_tokens_sent
    assert_equal [REFRESH_TOKEN_3], store.saved
  end

  def test_scopes_narrow_the_access_token
    @transport.on("POST", TOKEN_PATH, grant_token_reply("jwt-org", REFRESH_TOKEN_2))
    @transport.on("GET", LEARNER_PATH, OK)

    grant_client(MemoryStore.new(@transport), scopes: ["learners:read"]).learners.retrieve(LEARNER_ID)

    assert_equal "learners:read", form_of(only(@transport.requests_to("POST", TOKEN_PATH)))["scope"]
  end

  def test_a_store_that_loads_no_refresh_token_raises_before_any_exchange
    error = assert_raises(TeachMeHipaa::TokenStoreError) do
      grant_client(MemoryStore.new(@transport, "")).learners.retrieve(LEARNER_ID)
    end

    assert_match(/no Refresh token/, error.message)
    assert_empty @transport.requests
  end

  def test_the_provider_keeps_its_secrets_out_of_inspect
    provider = TeachMeHipaa::TokenProviders::PartnerGrant.new(
      client_id: APP_ID, client_secret: APP_SECRET, token_store: MemoryStore.new(@transport),
      refresh_token: REFRESH_TOKEN_1
    )

    refute_includes provider.inspect, APP_SECRET
    refute_includes provider.inspect, REFRESH_TOKEN_1
  end

  private

  def grant_client(store, clock: nil, **provider_options)
    provider = TeachMeHipaa::TokenProviders::PartnerGrant.new(
      client_id: APP_ID, client_secret: APP_SECRET, token_store: store, transport: @transport, clock:,
      **provider_options
    )
    TeachMeHipaa::Client.new(token_provider: provider, organization_id: ORG_ID, transport: @transport, clock:)
  end

  def form_of(request)
    URI.decode_www_form(request.body).to_h
  end

  def refresh_tokens_sent
    @transport.requests_to("POST", TOKEN_PATH).map { |r| form_of(r)["refresh_token"] }
  end

  def bearers
    @transport.requests_to("GET", LEARNER_PATH).map { |r| r.headers["authorization"] }
  end
end
