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

    attr_reader :config

    # +environment+ is :live or :sandbox; +base_url+ overrides it (for a mock
    # server, say). +scopes+ narrows the Access token to fewer Scopes than the
    # API client holds. +timeout+ is in seconds. +transport+ is any object
    # with +call(TeachMeHipaa::Transport::Request)+ returning a
    # TeachMeHipaa::Transport::Response. +logger+ receives one line per HTTP
    # exchange, without bodies. +app_info+ is a Hash with +:name+ and optional
    # +:version+ and +:url+, added to the User-Agent. +clock+ (monotonic
    # seconds) and +sleep+ are for tests.
    def initialize(client_id:, client_secret:, environment: :live, base_url: nil,
                   organization_id: nil, scopes: nil, max_retries: DEFAULT_MAX_RETRIES,
                   timeout: DEFAULT_TIMEOUT, transport: nil, logger: nil, app_info: nil,
                   clock: nil, sleep: nil)
      @config = Config.build(environment:, base_url:, organization_id:, max_retries:, timeout:,
                             app_info:, logger:, clock:, sleep:)
      connection = Core::Connection.new(@config, transport || Transport::NetHttp.new)
      token_provider = TokenProviders::ClientCredentials.new(client_id:, client_secret:, scopes:)
      build_resources(Core::Requestor.new(connection, token_provider))
      freeze
    end

    def environment = config.environment
    def base_url = config.base_url
    def max_retries = config.max_retries
    def timeout = config.timeout

    def inspect
      "#<#{self.class.name} environment=#{environment.inspect} base_url=#{base_url.inspect}>"
    end
  end
end
