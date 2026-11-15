# frozen_string_literal: true

module TeachMeHipaa
  # Token providers are the seam between the request pipeline and however an
  # Access token is obtained. A provider is any object whose
  # +access_token(connection)+ returns a current Access token String,
  # minting through +connection+ (a client's Core::Connection) when it needs
  # one, and whose +invalidate(access_token)+ forgets that token after the
  # API refused it, keeping any token minted since. Providers must be safe to
  # call from several threads.
  module TokenProviders
    # Re-mint this long before expiry so a token never lapses mid-request.
    REFRESH_MARGIN_SECONDS = 60

    # The OAuth client-credentials grant for an API client. Caches one Access
    # token and mints a new one when it nears expiry; concurrent callers
    # share a single mint.
    class ClientCredentials
      def initialize(client_id:, client_secret:, scopes: nil)
        @client_id = client_id
        @client_secret = client_secret
        @scopes = scopes&.map(&:to_s)&.freeze
        @lock = Mutex.new
        @token = nil
        @expires_at = nil
      end

      def access_token(connection)
        @lock.synchronize do
          mint(connection) if @token.nil? || stale?(connection.config.clock.call)
          @token
        end
      end

      def invalidate(access_token)
        @lock.synchronize do
          @token = nil if @token == access_token
        end
      end

      def inspect
        "#<#{self.class.name} client_id=#{@client_id.inspect}>"
      end

      private

      def stale?(now)
        now >= @expires_at - REFRESH_MARGIN_SECONDS
      end

      def mint(connection)
        minted_at = connection.config.clock.call
        response = Core::Retries.call(connection, mint_retry_policy(connection.config),
                                      map_error: Error.method(:from_oauth_response)) { mint_request }
        body = Core::Json.success_body(response)
        @token = body.fetch("access_token")
        @expires_at = minted_at + Float(body.fetch("expires_in"))
      end

      # A client-credentials grant mints a fresh token each time, so replaying
      # it is harmless. Refresh-token and authorization-code exchanges must
      # never retry: replaying one revokes the Grant (ADR-0004).
      def mint_retry_policy(config)
        Core::Retries::Policy.new(retry_safe: true, max_retries: config.max_retries)
      end

      def mint_request
        form = { "grant_type" => "client_credentials" }
        form["scope"] = @scopes.join(" ") unless @scopes.nil?
        Core::GrantExchange.token_request(@client_id, @client_secret, form)
      end
    end

    # Sends an Access token obtained elsewhere, as is. It is never renewed:
    # once it expires or is revoked, calls raise AuthenticationError.
    class Static
      def initialize(access_token)
        unless access_token.is_a?(String) && !access_token.strip.empty?
          raise ArgumentError, "TokenProviders::Static needs a non-empty Access token"
        end

        @access_token = access_token
      end

      def access_token(_connection)
        @access_token
      end

      # Nothing to drop: this provider can't get another token.
      def invalidate(_access_token); end

      def inspect
        "#<#{self.class.name}>"
      end
    end
  end
end
