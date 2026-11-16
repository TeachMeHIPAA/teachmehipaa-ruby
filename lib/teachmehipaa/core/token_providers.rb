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
  end

  module Core
    # One cached Access token, renewed when it nears expiry. Minting holds
    # the lock, so concurrent callers share a single mint.
    #
    # @api private
    class AccessTokenCache
      def initialize
        @lock = Mutex.new
        @token = nil
        @expires_at = nil
      end

      # The cached token, or the one the block mints when there is none or
      # it is stale by +clock+. The block returns the new token and its
      # expiry in +clock+'s seconds; if it raises, nothing is cached.
      def fetch(clock)
        @lock.synchronize do
          @token, @expires_at = yield if @token.nil? || stale?(clock.call)
          @token
        end
      end

      # Keeps a token minted since +access_token+ was handed out.
      def invalidate(access_token)
        @lock.synchronize do
          @token = nil if @token == access_token
        end
      end

      private

      def stale?(now)
        now >= @expires_at - TokenProviders::REFRESH_MARGIN_SECONDS
      end
    end
  end

  module TokenProviders
    # The OAuth client-credentials grant for an API client. Caches one Access
    # token and mints a new one when it nears expiry; concurrent callers
    # share a single mint.
    class ClientCredentials
      TOKEN_PATH = "/auth/token"
      private_constant :TOKEN_PATH

      def initialize(client_id:, client_secret:, scopes: nil)
        @client_id = client_id
        @client_secret = client_secret
        @scopes = scopes&.map(&:to_s)&.freeze
        @cache = Core::AccessTokenCache.new
      end

      # A current Access token, minted through +connection+ when none is
      # cached or the cached one nears expiry.
      # @return [String]
      def access_token(connection)
        @cache.fetch(connection.config.clock) { mint(connection) }
      end

      # Forgets +access_token+ after the API refused it, so the next call
      # mints another.
      # @return [void]
      def invalidate(access_token)
        @cache.invalidate(access_token)
      end

      # Shows the client id only, never the secret or a token.
      # @return [String]
      def inspect
        "#<#{self.class.name} client_id=#{@client_id.inspect}>"
      end

      private

      def mint(connection)
        minted_at = connection.config.clock.call
        response = Core::Retries.call(connection, mint_retry_policy(connection.config),
                                      map_error: Error.method(:from_oauth_response)) { mint_request }
        body = Core::Json.success_body(response)
        [body.fetch("access_token"), minted_at + Float(body.fetch("expires_in"))]
      end

      # A client-credentials grant mints a fresh token each time, so replaying
      # it is harmless.
      def mint_retry_policy(config)
        Core::Retries::Policy.new(retry_safe: true, max_retries: config.max_retries)
      end

      def mint_request
        form = { "grant_type" => "client_credentials" }
        form["scope"] = @scopes.join(" ") unless @scopes.nil?
        {
          method: "POST",
          path: TOKEN_PATH,
          headers: {
            "authorization" => "Basic #{basic_credentials}",
            "content-type" => "application/x-www-form-urlencoded",
          },
          body: URI.encode_www_form(form),
        }
      end

      # client_secret_basic, per RFC 6749 §2.3.1: form-encode each half
      # before base64.
      def basic_credentials
        pair = "#{URI.encode_www_form_component(@client_id)}:#{URI.encode_www_form_component(@client_secret)}"
        [pair].pack("m0")
      end
    end

    # Sends an Access token obtained elsewhere, as is. It is never renewed:
    # once it expires or is revoked, calls raise AuthenticationError.
    class Static
      def initialize(access_token)
        unless Core::Arguments.text?(access_token)
          raise ArgumentError, "TokenProviders::Static needs a non-empty Access token"
        end

        @access_token = access_token
      end

      # The token this provider was given.
      # @return [String]
      def access_token(_connection)
        @access_token
      end

      # Nothing to drop: this provider can't get another token.
      def invalidate(_access_token); end

      # Never shows the token.
      # @return [String]
      def inspect
        "#<#{self.class.name}>"
      end
    end
  end
end
