# frozen_string_literal: true

module TeachMeHipaa
  # A client for one Organization's view of the TeachMeHIPAA Developer API.
  #
  #   client = TeachMeHipaa::Client.new(client_id: "cli_...", client_secret: "tmh_cs_...")
  #   learner = client.learners.retrieve("sub_...")
  #
  # The client mints, caches and renews Access tokens itself, and discovers
  # the Organization its credential is bound to unless +organization_id:+ is
  # given. Its configuration is fixed at construction (ADR-0002); build
  # another client for other settings. A client is safe to share between
  # threads.
  class Client
    include Resources::Root

    # The frozen settings this client was built with.
    # @return [Config]
    attr_reader :config

    # Pass the API client's +client_id+ and +client_secret+, or a
    # +token_provider+ such as a TokenProviders::Static that supplies every
    # Access token instead.
    #
    # With none of them, the client can call only the methods that need no
    # Access token (the course catalog and Certificate verification); any
    # other call raises AuthenticationError before sending a request.
    #
    # +environment+ is :live or :sandbox; +base_url+ overrides it (for a mock
    # server, say). +scopes+ narrows the Access token to fewer Scopes than the
    # API client holds (a token provider takes its own). +timeout+ is in seconds. +transport+ is any object
    # with +call(TeachMeHipaa::Transport::Request)+ returning a
    # TeachMeHipaa::Transport::Response. +logger+ receives one line per HTTP
    # exchange, without bodies. +app_info+ is a Hash with +:name+ and optional
    # +:version+ and +:url+, added to the User-Agent. +clock+ (monotonic
    # seconds) and +sleep+ are for tests.
    def initialize(client_id: nil, client_secret: nil, token_provider: nil, environment: :live, base_url: nil,
                   organization_id: nil, scopes: nil, max_retries: DEFAULT_MAX_RETRIES,
                   timeout: DEFAULT_TIMEOUT, transport: nil, logger: nil, app_info: nil,
                   clock: nil, sleep: nil)
      token_provider = token_provider_for(client_id, client_secret, token_provider, scopes)
      @config = Config.build(environment:, base_url:, organization_id:, max_retries:, timeout:,
                             app_info:, logger:, clock:, sleep:)
      connection = Core::Connection.new(@config, transport || Transport::NetHttp.new)
      build_resources(Core::Requestor.new(connection, token_provider))
      freeze
    end

    # @return [Symbol] :live or :sandbox.
    def environment = config.environment
    # @return [String] The API's base URL, such as "https://api.tme.so/v1".
    def base_url = config.base_url
    # @return [Integer] How many times a failed call that is safe to replay is retried.
    def max_retries = config.max_retries
    # @return [Float] Seconds to wait to connect, and for each read and write.
    def timeout = config.timeout

    # TeachMeHipaa::Webhook, for verifying Deliveries. It needs only the
    # Signing secret, so it is also usable without a client.
    def webhooks = Webhook

    # Shows the Environment and base URL only, never credentials.
    # @return [String]
    def inspect
      "#<#{self.class.name} environment=#{environment.inspect} base_url=#{base_url.inspect}>"
    end

    private

    # The provider that supplies every Access token: the one given, a
    # client-credentials provider for the id and secret, or nil for a client
    # with no credentials, which can call only the methods that need no
    # Access token (spec story 27).
    def token_provider_for(client_id, client_secret, token_provider, scopes)
      given = { client_id:, client_secret:, scopes: }.compact.keys
      unless token_provider.nil?
        return token_provider if given.empty?

        raise ArgumentError, "give either token_provider or client_id and client_secret, not both " \
                             "(got #{given.join(", ")} too; scopes belong to the token provider)"
      end
      return nil if given.empty?
      return TokenProviders::ClientCredentials.new(client_id:, client_secret:, scopes:) if client_id && client_secret

      raise ArgumentError, "pass both client_id and client_secret, or token_provider (got only #{given.join(", ")})"
    end
  end
end
