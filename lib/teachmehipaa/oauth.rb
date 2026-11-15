# frozen_string_literal: true

module TeachMeHipaa
  # Helpers for an Organization's consent to a Partner app: PKCE pairs, the
  # consent URL and the code exchange. They need no client.
  #
  #   pair = TeachMeHipaa::OAuth.create_pkce_pair
  #   state = TeachMeHipaa::OAuth.create_state
  #   url = TeachMeHipaa::OAuth.authorize_url(client_id: "app_...", redirect_uri: "https://...",
  #                                           scopes: ["learners:read"], state:,
  #                                           code_challenge: pair.code_challenge)
  module OAuth
    # A PKCE code verifier and the challenge to put on the consent URL. Keep
    # +code_verifier+ server-side until the code exchange; never send it to
    # the browser. +code_challenge_method+ is always "S256", the only one
    # TeachMeHIPAA accepts (named for the consent URL's parameter, since a
    # +method+ member would hide Object#method).
    PkcePair = Data.define(:code_verifier, :code_challenge, :code_challenge_method) do
      def inspect
        "#<#{self.class.name} code_challenge=#{code_challenge.inspect} " \
          "code_challenge_method=#{code_challenge_method.inspect}>"
      end
      alias_method :to_s, :inspect
    end

    # What a Grant's token exchange returns. Save +refresh_token+ in the
    # token store before anything else: it replaces the one exchanged.
    # +expires_in+ is seconds until +access_token+ expires; +scopes+ are the
    # Scopes it carries.
    GrantTokens = Data.define(:access_token, :refresh_token, :expires_in, :scopes) do
      def inspect
        "#<#{self.class.name} expires_in=#{expires_in.inspect} scopes=#{scopes.inspect}>"
      end
      alias_method :to_s, :inspect
    end

    CODE_EXCHANGE_GUIDANCE = Core::GrantExchange::Guidance.new(
      network_failure: "The code exchange was not retried: the code may have been consumed, and a code " \
                       "works only once. Re-run consent to get a new code.",
      invalid_grant: nil,
    )
    private_constant :CODE_EXCHANGE_GUIDANCE

    # The Sandbox console's consent URL is not published yet, so Sandbox
    # callers pass +authorization_url:+ rather than the library guessing a
    # host.
    AUTHORIZATION_URLS = {
      live: "https://console.teachmehipaa.com/oauth/authorize",
      sandbox: nil,
    }.freeze

    module_function

    # A fresh code verifier and its S256 code challenge.
    def create_pkce_pair
      code_verifier = random_token
      PkcePair.new(code_verifier:, code_challenge: base64url(OpenSSL::Digest::SHA256.digest(code_verifier)),
                   code_challenge_method: "S256")
    end

    # A random +state+ that binds the consent redirect to the admin's
    # session.
    def create_state
      random_token
    end

    # The URL to send an Organization admin to, to grant the Partner app
    # access. +client_id+ is the Partner app's id (+app_...+);
    # +redirect_uri+ must match one of its registered redirect URIs exactly.
    # +state+ comes back on the redirect: check it matches before exchanging
    # the code. +code_challenge+ is from create_pkce_pair. Sandbox has no
    # built-in consent URL, so it needs +authorization_url:+, which overrides
    # the Environment's.
    def authorize_url(client_id:, redirect_uri:, scopes:, state:, code_challenge:, environment: :live,
                      authorization_url: nil)
      query = {
        "response_type" => "code",
        "client_id" => Core::Arguments.require_text(client_id, "client_id"),
        "redirect_uri" => Core::Arguments.require_text(redirect_uri, "redirect_uri"),
        "scope" => scopes.join(" "),
        # Without state, a forged redirect could attach an attacker's Grant
        # to the partner's session (RFC 6749 §10.12).
        "state" => Core::Arguments.require_text(state, "state"),
        "code_challenge" => Core::Arguments.require_text(code_challenge, "code_challenge"),
        "code_challenge_method" => "S256",
      }
      # Percent-encoding writes spaces as %20; form encoding's "+" is only
      # read back as a space by form parsers.
      encoded = query.map { |name, value| "#{name}=#{URI.encode_uri_component(value)}" }.join("&")
      base = consent_base_url(environment, authorization_url)
      "#{base}#{URI(base).query ? "&" : "?"}#{encoded}"
    end

    # Exchanges the redirect's +code+ for the Grant's first tokens, exactly
    # once, and returns GrantTokens. Save the Refresh token in your token
    # store before you use the Access token.
    #
    # +client_id+ and +client_secret+ are the Partner app's (+app_...+,
    # +tmh_as_...+). +code+ works once, within 10 minutes. +redirect_uri+ is
    # the one the consent URL carried and +code_verifier+ is from the
    # PkcePair behind it. +environment+ or +base_url+ picks the token
    # endpoint; +transport+ sends the request (see TeachMeHipaa::Transport).
    #
    # Raises OAuthError when the endpoint refuses the code, and
    # APIConnectionError when no response arrived: the code may have been
    # consumed, so re-run consent rather than retrying.
    def exchange_code(client_id:, client_secret:, code:, redirect_uri:, code_verifier:, environment: :live,
                      base_url: nil, timeout: DEFAULT_TIMEOUT, app_info: nil, transport: nil)
      form = {
        "grant_type" => "authorization_code",
        "code" => Core::Arguments.require_text(code, "code"),
        "redirect_uri" => Core::Arguments.require_text(redirect_uri, "redirect_uri"),
        "code_verifier" => Core::Arguments.require_text(code_verifier, "code_verifier"),
      }
      connection = Core::GrantExchange.connection(environment:, base_url:, timeout:, app_info:, transport:,
                                                  clock: nil)
      Core::GrantExchange.call(connection, client_id: Core::Arguments.require_text(client_id, "client_id"),
                                           client_secret: Core::Arguments.require_text(client_secret, "client_secret"),
                                           form:, guidance: CODE_EXCHANGE_GUIDANCE).tokens
    end

    # 32 bytes encode to 43 base64url characters: the shortest verifier RFC
    # 7636 allows, carrying the full 256 bits it recommends.
    def random_token
      SecureRandom.urlsafe_base64(32)
    end

    def base64url(bytes)
      [bytes].pack("m0").tr("+/", "-_").delete("=")
    end

    def consent_base_url(environment, authorization_url)
      unless authorization_url.nil?
        uri = URI(authorization_url)
        raise ArgumentError, "authorization_url must be an absolute URL" unless uri.absolute? && uri.host

        return authorization_url
      end
      environment = Config.check_environment(environment)
      AUTHORIZATION_URLS.fetch(environment) or
        raise ArgumentError, "pass authorization_url: the #{environment} consent URL is not built in"
    end

    private_class_method :random_token, :base64url, :consent_base_url
  end
end
