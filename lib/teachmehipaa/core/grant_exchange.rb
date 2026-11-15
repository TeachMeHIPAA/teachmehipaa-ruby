# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # Token endpoint requests, and one +authorization_code+ or
    # +refresh_token+ exchange sent exactly once. Replaying a spent code or a
    # superseded Refresh token revokes the Grant (ADR-0004), so a failure is
    # raised with guidance instead of retried.
    #
    # @api private
    module GrantExchange
      TOKEN_PATH = "/auth/token"
      NEVER_RETRY = Retries::Policy.new(retry_safe: false, max_retries: 0)

      # What to tell the caller when an exchange fails in a way only they can
      # fix: +network_failure+ when no response arrived, so the outcome is
      # unknown, and +invalid_grant+ for that OAuth error, or nil to keep the
      # endpoint's words.
      Guidance = Data.define(:network_failure, :invalid_grant)

      # +requested_at+ is when the request left, so expiry can't stretch past
      # the token's real lifetime.
      Exchange = Data.define(:tokens, :requested_at) do
        def expires_at = requested_at + tokens.expires_in
      end

      module_function

      # A connection to the token endpoint of a Partner app's Environment,
      # for exchanges made outside any client.
      def connection(environment:, base_url:, timeout:, app_info:, transport:, clock:)
        config = Config.build(environment:, base_url:, organization_id: nil, max_retries: 0, timeout:,
                              app_info:, logger: nil, clock:, sleep: nil)
        Connection.new(config, transport || Transport::NetHttp.new)
      end

      def call(connection, client_id:, client_secret:, form:, guidance:)
        requested_at = connection.config.clock.call
        response = Retries.call(connection, NEVER_RETRY, map_error: Error.method(:from_oauth_response)) do
          token_request(client_id, client_secret, form)
        end
        Exchange.new(tokens: read_tokens(response), requested_at:)
      rescue APIConnectionError, OAuthError => e
        raise guided(e, guidance), cause: e.cause
      end

      # A request to the token endpoint, authenticated with client_secret_basic.
      def token_request(client_id, client_secret, form)
        {
          method: "POST",
          path: TOKEN_PATH,
          headers: {
            "authorization" => "Basic #{basic_credentials(client_id, client_secret)}",
            "content-type" => "application/x-www-form-urlencoded",
          },
          body: URI.encode_www_form(form),
        }
      end

      # RFC 6749 §2.3.1: form-encode each half before base64.
      def basic_credentials(client_id, client_secret)
        pair = "#{URI.encode_www_form_component(client_id)}:#{URI.encode_www_form_component(client_secret)}"
        [pair].pack("m0")
      end

      def read_tokens(response)
        body = Json.success_body(response)
        raise not_a_grant(response) unless body.is_a?(Hash)

        access_token, refresh_token, expires_in, scope = body.values_at("access_token", "refresh_token",
                                                                        "expires_in", "scope")
        unless access_token.is_a?(String) && refresh_token.is_a?(String) && !refresh_token.empty? &&
               expires_in.is_a?(Numeric)
          raise not_a_grant(response)
        end

        OAuth::GrantTokens.new(access_token:, refresh_token:, expires_in: expires_in.to_f,
                               scopes: scope.is_a?(String) ? scope.split.freeze : [].freeze)
      end

      # No body: it may hold a live Access token, which must not reach error
      # reporters.
      def not_a_grant(response)
        APIError.new("The token endpoint answered without an access_token, refresh_token and expires_in.",
                     status: response.status, request_id: response.headers["x-request-id"])
      end

      # The same error with what only the caller can do about it appended.
      def guided(error, guidance)
        if error.is_a?(APIConnectionError)
          error.class.new(append(error.message, guidance.network_failure))
        elsif error.code == "invalid_grant" && guidance.invalid_grant
          OAuthError.new(append(error.detail || error.code, guidance.invalid_grant),
                         status: error.status, code: error.code, detail: error.detail,
                         request_id: error.request_id, headers: error.headers, body: error.body)
        else
          error
        end
      end

      def append(message, guidance)
        "#{message.delete_suffix(".")}. #{guidance}"
      end

      private_class_method :basic_credentials, :read_tokens, :not_a_grant, :guided, :append
    end
  end
end
