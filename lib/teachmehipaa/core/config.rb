# frozen_string_literal: true

module TeachMeHipaa
  ENVIRONMENTS = {
    live: "https://api.tme.so/v1",
    sandbox: "https://api-teachmehipaa-dev.web.app/v1",
  }.freeze

  DEFAULT_MAX_RETRIES = 2
  DEFAULT_TIMEOUT = 80.0

  # A client's settings, fixed at construction (ADR-0002). +clock+ returns
  # monotonic seconds and +sleep+ waits; both are injectable so tests run
  # without real time passing.
  Config = Data.define(
    :environment, :base_url, :organization_id, :max_retries, :timeout, :user_agent,
    :logger, :clock, :sleep
  ) do
    def self.build(environment:, base_url:, organization_id:, max_retries:, timeout:,
                   app_info:, logger:, clock:, sleep:)
      environment = environment.to_sym
      new(
        environment: check_environment(environment),
        base_url: (base_url || ENVIRONMENTS.fetch(environment)).chomp("/").freeze,
        organization_id: organization_id&.dup&.freeze,
        max_retries: check_max_retries(max_retries),
        timeout: check_timeout(timeout),
        user_agent: user_agent(app_info),
        logger:,
        clock: clock || -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) },
        sleep: sleep || ->(seconds) { Kernel.sleep(seconds) },
      )
    end

    def self.check_environment(environment)
      return environment if ENVIRONMENTS.key?(environment)

      raise ArgumentError, "environment must be :live or :sandbox, not #{environment.inspect}"
    end

    def self.check_max_retries(max_retries)
      return max_retries if max_retries.is_a?(Integer) && max_retries >= 0

      raise ArgumentError, "max_retries must be an Integer of zero or more"
    end

    def self.check_timeout(timeout)
      return timeout.to_f if timeout.is_a?(Numeric) && timeout.positive?

      raise ArgumentError, "timeout must be a positive number of seconds"
    end

    # A call's +request_options:+, checked, with the timeout as a Float.
    # +request_id+ is sent as x-request-id, to correlate the caller's logs
    # with TeachMeHIPAA support; the API replaces one that doesn't match
    # /\A[A-Za-z0-9._-]{1,128}\z/.
    def self.check_request_options(options)
      unknown = options.keys - %i[headers timeout max_retries idempotency_key request_id]
      raise ArgumentError, "unknown request option(s): #{unknown.map(&:inspect).join(", ")}" unless unknown.empty?

      check_max_retries(options[:max_retries]) if options.key?(:max_retries)
      return options unless options.key?(:timeout)

      options.merge(timeout: check_timeout(options[:timeout]))
    end

    def self.user_agent(app_info)
      agent = "teachmehipaa-ruby/#{VERSION} ruby/#{RUBY_VERSION}"
      return agent.freeze if app_info.nil?

      app = app_info.fetch(:name).dup
      app << "/#{app_info[:version]}" if app_info[:version]
      app << " (#{app_info[:url]})" if app_info[:url]
      "#{agent} #{app}".freeze
    end

    private_class_method :check_environment, :user_agent
  end
end
