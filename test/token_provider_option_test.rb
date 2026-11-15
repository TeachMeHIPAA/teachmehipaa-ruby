# frozen_string_literal: true

require_relative "test_helper"

class TokenProviderOptionTest < Minitest::Test
  include ClientHelpers

  UNAUTHORIZED = Fixtures.problem(401, "unauthorized", title: "Unauthorized")
  PARTNER_ID = "ptn_01JD82ZX4C5V6B7N8M9Q0W1E2R"

  def setup
    @transport = FakeTransport.new
  end

  def test_a_static_token_is_sent_as_is_and_the_token_endpoint_is_never_called
    @transport.on("GET", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))
    client = static_client("jwt-from-elsewhere")

    client.learners.retrieve(LEARNER_ID)
    client.learners.retrieve(LEARNER_ID)

    assert_empty @transport.requests_to("POST", "/auth/token")
    assert_equal ["Bearer jwt-from-elsewhere"] * 2, bearers
  end

  def test_a_static_token_refused_with_401_is_sent_once
    @transport.on("GET", LEARNER_PATH, UNAUTHORIZED)

    assert_raises(TeachMeHipaa::AuthenticationError) { static_client("jwt-expired").learners.retrieve(LEARNER_ID) }

    assert_equal 1, @transport.requests.length
  end

  def test_a_static_token_must_not_be_empty
    error = assert_raises(ArgumentError) { TeachMeHipaa::TokenProviders::Static.new("") }

    assert_match(/Access token/, error.message)
  end

  def test_a_static_provider_keeps_its_token_out_of_inspect
    refute_includes TeachMeHipaa::TokenProviders::Static.new("jwt-secret").inspect, "jwt-secret"
  end

  def test_a_token_provider_cannot_be_combined_with_credentials_or_scopes
    [
      { client_id: CLIENT_ID, client_secret: CLIENT_SECRET },
      { client_id: CLIENT_ID },
      { client_secret: CLIENT_SECRET },
      { scopes: ["learners:read"] },
    ].each do |conflicting|
      error = assert_raises(ArgumentError, conflicting.inspect) do
        TeachMeHipaa::Client.new(token_provider: TeachMeHipaa::TokenProviders::Static.new("jwt"), **conflicting)
      end

      assert_match(/either token_provider or client_id/, error.message)
    end
  end

  def test_a_client_needs_credentials_or_a_token_provider
    error = assert_raises(ArgumentError) { TeachMeHipaa::Client.new(client_id: CLIENT_ID) }

    assert_match(/client_id and client_secret/, error.message)
  end

  def test_a_partner_apps_own_credentials_call_partners_without_an_organization
    partner_token = { "access_token" => "jwt-partner", "token_type" => "Bearer", "expires_in" => 900,
                      "scope" => "partner:orgs:read partner:orgs:write" }
    partner = { "partnerId" => PARTNER_ID, "name" => "Reseller Co", "appId" => APP_ID, "status" => "active",
                "maxChildOrgs" => 50, "childOrgCount" => 3, "createdAt" => "2026-11-01T09:00:00.000Z" }
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(partner_token))
    @transport.on("GET", "/partners/#{PARTNER_ID}", FakeTransport::Reply.json(partner))
    client = TeachMeHipaa::Client.new(client_id: APP_ID, client_secret: APP_SECRET, transport: @transport)

    retrieved = client.partners.retrieve(PARTNER_ID)

    assert_equal PARTNER_ID, retrieved.partner_id
    assert_empty @transport.requests_to("GET", "/auth/introspection")
    assert_equal "Basic #{APP_BASIC_CREDENTIALS}", only(@transport.requests_to("POST", "/auth/token"))
      .headers["authorization"]
    assert_equal "Bearer jwt-partner", only(@transport.requests_to("GET", "/partners/#{PARTNER_ID}"))
      .headers["authorization"]
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
