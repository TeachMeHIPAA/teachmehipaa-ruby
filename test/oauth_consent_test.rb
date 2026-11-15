# frozen_string_literal: true

require_relative "test_helper"
require "digest"

class OAuthConsentTest < Minitest::Test
  include ClientHelpers

  UNRESERVED_43_TO_128 = /\A[A-Za-z0-9._~-]{43,128}\z/
  BASE64URL_43 = /\A[A-Za-z0-9_-]{43}\z/
  REDIRECT_URI = "https://partner.example.com/oauth/callback?tenant=7"
  # RFC 7636 appendix B: this verifier's S256 challenge.
  VERIFIER = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
  CHALLENGE = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
  CODE = "SplxlOBeZQQYbYS6WxSbIA"
  CONSENT = {
    client_id: Fixtures::APP_ID,
    redirect_uri: REDIRECT_URI,
    scopes: %w[learners:read learners:write],
    state: "af0ifjsldkj",
    code_challenge: CHALLENGE,
  }.freeze
  EXCHANGE = {
    client_id: Fixtures::APP_ID,
    client_secret: Fixtures::APP_SECRET,
    code: CODE,
    redirect_uri: REDIRECT_URI,
    code_verifier: VERIFIER,
  }.freeze

  def test_the_code_challenge_is_the_s256_hash_of_the_code_verifier
    pair = TeachMeHipaa::OAuth.create_pkce_pair

    assert_equal "S256", pair.code_challenge_method
    assert_match UNRESERVED_43_TO_128, pair.code_verifier
    assert_match BASE64URL_43, pair.code_challenge
    assert_equal s256(pair.code_verifier), pair.code_challenge
  end

  def test_every_pkce_pair_has_a_fresh_code_verifier
    refute_equal TeachMeHipaa::OAuth.create_pkce_pair.code_verifier,
                 TeachMeHipaa::OAuth.create_pkce_pair.code_verifier
  end

  def test_the_consent_url_carries_client_redirect_scopes_state_and_s256
    url = URI(TeachMeHipaa::OAuth.authorize_url(**CONSENT))

    assert_equal "https://console.teachmehipaa.com/oauth/authorize", "#{url.scheme}://#{url.host}#{url.path}"
    assert_equal(
      {
        "response_type" => "code",
        "client_id" => APP_ID,
        "redirect_uri" => REDIRECT_URI,
        "scope" => "learners:read learners:write",
        "state" => "af0ifjsldkj",
        "code_challenge" => CHALLENGE,
        "code_challenge_method" => "S256",
      },
      URI.decode_www_form(url.query).to_h,
    )
  end

  def test_the_consent_url_percent_encodes_spaces_in_the_scope
    assert_includes TeachMeHipaa::OAuth.authorize_url(**CONSENT), "scope=learners%3Aread%20learners%3Awrite"
  end

  def test_a_consent_url_needs_a_state
    error = assert_raises(ArgumentError) { TeachMeHipaa::OAuth.authorize_url(**CONSENT, state: "") }

    assert_match(/state/, error.message)
  end

  def test_states_are_hard_to_guess
    state = TeachMeHipaa::OAuth.create_state

    assert_match BASE64URL_43, state
    refute_equal state, TeachMeHipaa::OAuth.create_state
  end

  def test_sandbox_consent_needs_an_explicit_authorization_url
    error = assert_raises(ArgumentError) { TeachMeHipaa::OAuth.authorize_url(**CONSENT, environment: :sandbox) }

    assert_match(/authorization_url/, error.message)

    url = URI(TeachMeHipaa::OAuth.authorize_url(**CONSENT, environment: :sandbox,
                                                           authorization_url: "https://console.example.test/oauth/authorize"))

    assert_equal "https://console.example.test/oauth/authorize", "#{url.scheme}://#{url.host}#{url.path}"
    assert_equal "S256", URI.decode_www_form(url.query).to_h["code_challenge_method"]
  end

  def test_the_code_exchange_returns_the_grant_tokens
    transport = FakeTransport.new.on("POST", "/auth/token", grant_token_reply("jwt-org", REFRESH_TOKEN_1))

    grant = TeachMeHipaa::OAuth.exchange_code(**EXCHANGE, transport:)

    assert_equal "jwt-org", grant.access_token
    assert_equal REFRESH_TOKEN_1, grant.refresh_token
    assert_in_delta 900.0, grant.expires_in
    assert_equal %w[learners:read learners:write], grant.scopes
    exchange = only(transport.requests)

    assert_equal "https://api.tme.so/v1/auth/token", exchange.url
    assert_equal "Basic #{APP_BASIC_CREDENTIALS}", exchange.headers["authorization"]
    assert_equal "application/x-www-form-urlencoded", exchange.headers["content-type"]
    assert_equal(
      {
        "grant_type" => "authorization_code",
        "code" => CODE,
        "redirect_uri" => REDIRECT_URI,
        "code_verifier" => VERIFIER,
      },
      URI.decode_www_form(exchange.body).to_h,
    )
  end

  def test_grant_tokens_keep_their_secrets_out_of_inspect
    transport = FakeTransport.new.on("POST", "/auth/token", grant_token_reply("jwt-org", REFRESH_TOKEN_1))

    grant = TeachMeHipaa::OAuth.exchange_code(**EXCHANGE, transport:)

    refute_includes grant.inspect, "jwt-org"
    refute_includes grant.inspect, REFRESH_TOKEN_1
    refute_includes grant.to_s, REFRESH_TOKEN_1
  end

  def test_the_code_exchange_goes_to_the_sandbox_token_endpoint_when_asked
    transport = FakeTransport.new(SANDBOX_BASE)
                             .on("POST", "/auth/token", grant_token_reply("jwt-org", REFRESH_TOKEN_1))

    TeachMeHipaa::OAuth.exchange_code(**EXCHANGE, environment: :sandbox, transport:)

    assert_equal "https://api-teachmehipaa-dev.web.app/v1/auth/token", only(transport.requests).url
  end

  def test_a_refused_code_raises_an_oauth_error
    refused = oauth_error_reply("invalid_grant", "The code has expired or was used")
    transport = FakeTransport.new.on("POST", "/auth/token", refused)

    error = assert_raises(TeachMeHipaa::OAuthError) { TeachMeHipaa::OAuth.exchange_code(**EXCHANGE, transport:) }

    assert_equal "invalid_grant", error.code
    assert_equal 400, error.status
  end

  def test_a_network_failure_is_never_retried_and_says_the_code_may_be_spent
    transport = FakeTransport.new.on("POST", "/auth/token", NETWORK_ERROR)

    error = assert_raises(TeachMeHipaa::APIConnectionError) do
      TeachMeHipaa::OAuth.exchange_code(**EXCHANGE, transport:)
    end

    assert_match(/consumed/, error.message)
    assert_match(/consent/, error.message)
    assert_equal 1, transport.requests.length
  end

  def test_a_server_error_is_never_retried_either
    unavailable = oauth_error_reply("temporarily_unavailable", "Try later", status: 503)
    transport = FakeTransport.new.on("POST", "/auth/token", unavailable)

    assert_raises(TeachMeHipaa::OAuthError) { TeachMeHipaa::OAuth.exchange_code(**EXCHANGE, transport:) }

    assert_equal 1, transport.requests.length
  end

  def test_a_token_response_without_a_refresh_token_raises_an_api_error_without_the_body
    transport = FakeTransport.new.on("POST", "/auth/token", FakeTransport::Reply.json(token_json("jwt-org")))

    error = assert_raises(TeachMeHipaa::APIError) { TeachMeHipaa::OAuth.exchange_code(**EXCHANGE, transport:) }

    # The body holds a live Access token, which must not reach error reporters.
    assert_nil error.body
    refute_includes error.message, "jwt-org"
  end

  private

  # RFC 7636 §4.2, computed here rather than by the SDK.
  def s256(code_verifier)
    [Digest::SHA256.digest(code_verifier)].pack("m0").tr("+/", "-_").delete("=")
  end
end
