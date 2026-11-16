# frozen_string_literal: true

require_relative "test_helper"

class TokenProviderOptionTest < Minitest::Test
  include ClientHelpers

  UNAUTHORIZED = Fixtures.problem(401, "unauthorized", title: "Unauthorized")

  def setup
    @transport = FakeTransport.new
  end

  def test_a_static_token_is_sent_as_is_and_the_token_endpoint_is_never_called
    @transport.on("GET", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))
    client = static_client("access-token-from-elsewhere")

    client.learners.retrieve(LEARNER_ID)
    client.learners.retrieve(LEARNER_ID)

    assert_empty @transport.requests_to("POST", "/auth/token")
    assert_equal ["Bearer access-token-from-elsewhere"] * 2, bearers
  end

  def test_a_static_token_refused_with_401_is_sent_once
    @transport.on("GET", LEARNER_PATH, UNAUTHORIZED)

    assert_raises(TeachMeHipaa::AuthenticationError) { static_client("access-token-expired").learners.retrieve(LEARNER_ID) }

    assert_equal 1, @transport.requests.length
  end

  def test_a_static_token_must_not_be_empty
    error = assert_raises(ArgumentError) { TeachMeHipaa::TokenProviders::Static.new("") }

    assert_match(/Access token/, error.message)
  end

  def test_a_static_provider_keeps_its_token_out_of_inspect
    refute_includes TeachMeHipaa::TokenProviders::Static.new("access-token-secret").inspect, "access-token-secret"
  end

  def test_a_token_provider_cannot_be_combined_with_credentials_or_scopes
    [
      { client_id: CLIENT_ID, client_secret: CLIENT_SECRET },
      { client_id: CLIENT_ID },
      { client_secret: CLIENT_SECRET },
      { scopes: ["learners:read"] },
    ].each do |conflicting|
      error = assert_raises(ArgumentError, conflicting.inspect) do
        TeachMeHipaa::Client.new(token_provider: TeachMeHipaa::TokenProviders::Static.new("access-token-x"),
                                 **conflicting)
      end

      assert_match(/either token_provider or client_id/, error.message)
    end
  end

  def test_a_client_needs_credentials_or_a_token_provider
    error = assert_raises(ArgumentError) { TeachMeHipaa::Client.new(client_id: CLIENT_ID) }

    assert_match(/client_id and client_secret/, error.message)
  end

  private

  def static_client(access_token)
    TeachMeHipaa::Client.new(token_provider: TeachMeHipaa::TokenProviders::Static.new(access_token),
                             organization_id: ORG_ID, transport: @transport)
  end

  def bearers
    @transport.requests_to("GET", LEARNER_PATH).map { |r| r.headers["authorization"] }
  end
end
