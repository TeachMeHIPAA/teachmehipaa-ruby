# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # The request pipeline behind every resource method: binds the
    # Organization, authorizes, attaches the Idempotency-Key, sends with
    # retries and reads the response into a model.
    #
    # @api private
    class Requestor
      INTROSPECTION_PATH = "/auth/introspection"
      ORG_PLACEHOLDER = "{orgId}"
      REQUEST_OPTIONS = %i[headers timeout max_retries idempotency_key].freeze
      # Never replayed once a response may have been received (grilling
      # Q18): a lost success would apply twice or surface as a confusing
      # 412 or 404.
      NEVER_RETRIED = %w[PATCH DELETE].freeze

      def initialize(connection, token_provider)
        @connection = connection
        @token_provider = token_provider
        @organization_id = connection.config.organization_id
        @organization_lock = Mutex.new
      end

      # +path+ is the spec's path template, such as
      # "/organizations/{orgId}/learners/{learnerId}". "{orgId}" is filled
      # from the client's Organization binding, never by the caller
      # (ADR-0003).
      #
      # +body+ is a Hash sent as JSON with +content_type+. +retry_safe+ and
      # +idempotency_key+ (:required or nil) come from the IR; a call that
      # carries an Idempotency-Key is retry-safe either way.
      def request(method:, path:, model:, path_params: {}, query: {}, headers: {}, body: nil,
                  content_type: "application/json", retry_safe: false, idempotency_key: nil, request_options: {})
        options = check_request_options(request_options)
        # One key per call, not per attempt, so every retry and the 401
        # replay is recognised as the same request.
        key = options.fetch(:idempotency_key) { SecureRandom.uuid if idempotency_key == :required }
        params = path_params.transform_keys(&:to_s)
        params["orgId"] = organization_id if path.include?(ORG_PLACEHOLDER)
        request = {
          method:,
          path: expand(path, params),
          query:,
          headers: request_headers(headers, body && content_type, key, options.fetch(:headers, {})),
          body: body && JSON.generate(body),
          timeout: options[:timeout],
        }
        policy = Retries::Policy.new(retry_safe: retry_safe?(method, retry_safe, key),
                                     max_retries: options.fetch(:max_retries, @connection.config.max_retries))
        response = authorized(request, policy)
        model.new(Json.success_body(response), last_response: LastResponse.from(response))
      end

      private

      def authorized(request, policy)
        Retries.call(@connection, policy, map_error: Error.method(:from_response),
                                          replay: method(:invalidate_refused_token)) do
          token = @token_provider.access_token(@connection)
          request.merge(headers: request[:headers].merge("authorization" => "Bearer #{token}"))
        end
      end

      # Only the token the API refused is dropped, so concurrent calls that
      # were refused together share one fresh token.
      def invalidate_refused_token(request)
        @token_provider.invalidate(request[:headers]["authorization"].delete_prefix("Bearer "))
      end

      def request_headers(headers, content_type, idempotency_key, extra)
        headers = headers.dup
        headers["content-type"] = content_type if content_type
        headers["idempotency-key"] = idempotency_key if idempotency_key
        headers.merge(extra)
      end

      def retry_safe?(method, retry_safe, idempotency_key)
        !NEVER_RETRIED.include?(method) && (retry_safe || !idempotency_key.nil?)
      end

      def organization_id
        @organization_lock.synchronize do
          @organization_id ||= introspect_organization_id
        end
      end

      def introspect_organization_id
        policy = Retries::Policy.new(retry_safe: true, max_retries: @connection.config.max_retries)
        response = authorized({ method: "GET", path: INTROSPECTION_PATH, headers: {} }, policy)
        organization_id = Json.success_body(response)["orgId"]
        return organization_id if organization_id.is_a?(String)

        raise Error.new(
          "The access token is not bound to an Organization. Partner-level tokens " \
          "cannot call Organization endpoints.",
          status: response.status, request_id: response.headers["x-request-id"],
          headers: response.headers
        )
      end

      # Only ids are escaped, so a Custom method's literal ":verb" suffix
      # survives.
      def expand(template, params)
        template.gsub(/\{(\w+)\}/) { URI.encode_uri_component(params.fetch(Regexp.last_match(1))) }
      end

      def check_request_options(options)
        unknown = options.keys - REQUEST_OPTIONS
        raise ArgumentError, "unknown request option(s): #{unknown.map(&:inspect).join(", ")}" unless unknown.empty?

        Config.check_max_retries(options[:max_retries]) if options.key?(:max_retries)
        return options unless options.key?(:timeout)

        options.merge(timeout: Config.check_timeout(options[:timeout]))
      end
    end
  end
end
