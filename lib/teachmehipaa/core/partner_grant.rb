# frozen_string_literal: true

module TeachMeHipaa
  module TokenProviders
    # Access tokens for one Grant, from its rotating Refresh token.
    #
    #   provider = TeachMeHipaa::TokenProviders::PartnerGrant.new(
    #     client_id: "app_...", client_secret: "tmh_as_...", token_store: GrantStore.new(org)
    #   )
    #   client = TeachMeHipaa::Client.new(token_provider: provider)
    #
    # Create one provider per Grant and share it between clients: its lock is
    # what keeps two exchanges of the same Refresh token from racing. Each
    # rotated Refresh token goes to the token store before its Access token
    # is used, and an exchange is never retried (ADR-0004).
    #
    # +token_store+ is where the Grant's Refresh token lives between
    # processes, such as a database row or a secrets manager. It answers
    # +load+ with the current Refresh token (read once, at the first
    # exchange) and +save(refresh_token)+ by persisting the one that replaces
    # it. Presenting a replaced Refresh token revokes the Grant, so +save+
    # must persist durably before it returns.
    class PartnerGrant
      REFRESH_GUIDANCE = Core::GrantExchange::Guidance.new(
        network_failure: "The Refresh token exchange was not retried, because replaying a Refresh token the " \
                         "endpoint may already have rotated revokes the Grant. If the next call fails with " \
                         "invalid_grant, re-run consent for this Organization.",
        invalid_grant: "The Grant was revoked, or its Refresh token was reused (presenting a superseded " \
                       "Refresh token revokes the Grant). Re-run consent so the Organization authorizes the " \
                       "Partner app again.",
      )
      private_constant :REFRESH_GUIDANCE

      # +client_id+ and +client_secret+ are the Partner app's (+app_...+,
      # +tmh_as_...+). +refresh_token+ is for the first exchange, such as
      # straight from OAuth.exchange_code; without it, the first exchange
      # loads one from +token_store+. +scopes+ narrows the Access token; it
      # can never widen it. +environment+ or +base_url+ picks the token
      # endpoint, which must be the Environment of the clients using this
      # provider. +transport+ sends exchanges (see TeachMeHipaa::Transport),
      # and +clock+ (monotonic seconds) is for tests.
      def initialize(client_id:, client_secret:, token_store:, refresh_token: nil, scopes: nil,
                     environment: :live, base_url: nil, timeout: DEFAULT_TIMEOUT, app_info: nil,
                     transport: nil, clock: nil)
        @client_id = Core::Arguments.require_text(client_id, "client_id")
        @client_secret = Core::Arguments.require_text(client_secret, "client_secret")
        unless token_store.respond_to?(:load) && token_store.respond_to?(:save)
          raise ArgumentError, "token_store must respond to load and save(refresh_token)"
        end

        @token_store = token_store
        @refresh_token = refresh_token && Core::Arguments.require_text(refresh_token, "refresh_token")
        @scope = scopes&.join(" ")
        @connection = Core::GrantExchange.connection(environment:, base_url:, timeout:, app_info:, transport:,
                                                     clock:)
        @cache = Core::AccessTokenCache.new
      end

      # The API base URL of the token endpoint this provider exchanges at; a
      # client must call the same one.
      def base_url = @connection.config.base_url

      # The client's connection goes unused: exchanges go to this provider's
      # own token endpoint, so one provider can serve several clients.
      def access_token(_connection)
        @cache.fetch(@connection.config.clock) { mint }
      end

      def invalidate(access_token)
        @cache.invalidate(access_token)
      end

      def inspect
        "#<#{self.class.name} client_id=#{@client_id.inspect}>"
      end

      private

      def mint
        exchange = Core::GrantExchange.call(@connection, client_id: @client_id, client_secret: @client_secret,
                                                         form: refresh_form, guidance: REFRESH_GUIDANCE)
        tokens = exchange.tokens
        # The token just presented is superseded whatever happens next, so
        # this process must never present it again, even if the save fails.
        @refresh_token = tokens.refresh_token
        save(tokens.refresh_token)
        [tokens.access_token, exchange.expires_at]
      end

      def refresh_form
        form = { "grant_type" => "refresh_token", "refresh_token" => current_refresh_token }
        form["scope"] = @scope unless @scope.nil?
        form
      end

      def current_refresh_token
        return @refresh_token unless @refresh_token.nil?

        loaded = @token_store.load
        return loaded if Core::Arguments.text?(loaded)

        raise TokenStoreError, "token_store.load returned no Refresh token."
      end

      # The store didn't record the rotation, so the next process would load
      # and replay the superseded token and revoke the Grant. Using the new
      # Access token would hide that until it's too late, so raise instead.
      def save(refresh_token)
        @token_store.save(refresh_token)
      rescue StandardError
        raise TokenStoreError, "token_store.save failed, so the new Access token was not used. Until a save " \
                               "succeeds, your store holds a superseded Refresh token, and exchanging it " \
                               "would revoke the Grant."
      end
    end
  end
end
