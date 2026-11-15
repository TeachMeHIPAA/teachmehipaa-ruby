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
      # +body+ is a Hash of wire-named fields, sent as JSON with
      # +content_type+, or as multipart/form-data with +binary_parts+ (field
      # name => content type) sent as files. +retry_safe+ and
      # +idempotency_key+ (:required or nil) come from the IR; a call that
      # carries an Idempotency-Key is retry-safe either way.
      #
      # +response+ is the IR's response kind: :model (+model+ reads the
      # body), :page (+model+ reads each item), :write_result, :empty, or
      # :binary (the body must be of media type +accept+). A :page also takes
      # the IR's +pagination+: +{ style: :cursor | :after, cursor_param: }+.
      def request(method:, path:, model: nil, path_params: {}, query: {}, headers: {}, body: nil,
                  content_type: "application/json", binary_parts: {}, retry_safe: false, idempotency_key: nil,
                  response: :model, accept: nil, pagination: nil, request_options: {})
        options = check_request_options(request_options)
        # One key per call, not per attempt, so every retry and the 401
        # replay is recognised as the same request.
        key = options.fetch(:idempotency_key) { SecureRandom.uuid if idempotency_key == :required }
        encoded, encoded_type = encode(body, content_type, binary_parts)
        request = {
          method:,
          path: expand(path, path_params),
          query: Values.write(nil, query),
          headers: request_headers(headers.merge(accept ? { "accept" => accept } : {}), encoded_type, key,
                                   options.fetch(:headers, {})),
          body: encoded,
          timeout: options[:timeout],
        }
        policy = Retries::Policy.new(retry_safe: retry_safe?(method, retry_safe, key),
                                     max_retries: options.fetch(:max_retries, @connection.config.max_retries))
        return read_page(request, policy, model, pagination) if response == :page

        Responses.read(authorized(request, policy), response, model, accept)
      end

      def config
        @connection.config
      end

      private

      # Each later page is this request again with only the cursor parameter
      # changed, so filters, the limit and request options carry over.
      def read_page(request, policy, model, pagination)
        fetch_next = pagination && lambda do |page|
          position = Pagination.position(pagination.fetch(:style), page)
          query = request[:query].merge(pagination.fetch(:cursor_param) => position)
          read_page(request.merge(query:), policy, model, pagination)
        end
        Responses.read(authorized(request, policy), :page, model, nil, fetch_next:)
      end

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
      def expand(template, path_params)
        params = path_params.transform_keys(&:to_s)
        params["orgId"] = organization_id if template.include?(ORG_PLACEHOLDER)
        template.gsub(/\{(\w+)\}/) { URI.encode_uri_component(params.fetch(Regexp.last_match(1))) }
      end

      def encode(body, content_type, binary_parts)
        return [nil, nil] if body.nil?
        return Multipart.encode(body, binary_parts) if content_type == "multipart/form-data"

        [JSON.generate(body), content_type]
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
