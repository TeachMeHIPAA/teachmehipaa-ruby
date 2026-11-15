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
      # Never replayed once a response may have been received (grilling
      # Q18): a lost success would apply twice or surface as a confusing
      # 412 or 404.
      NEVER_RETRIED = %w[PATCH DELETE].freeze
      # Errors come as RFC 9457 problems whatever a download's own type.
      PROBLEM_JSON = "application/problem+json"

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
      # +if_match+ and +if_none_match+ are ETags for the conditional headers:
      # a String, or an object the client returned (its last response's
      # ETag).
      #
      # +response+ is the IR's response kind: :model (+model+ reads the
      # body), :page (+model+ reads each item), :write_result, :empty, or
      # :binary (the body must be of media type +accept+). A :page also takes
      # the IR's +pagination+: +{ style: :cursor | :after, cursor_param: }+.
      # A :binary call given a block streams the body to it instead.
      def request(method:, path:, model: nil, path_params: {}, query: {}, body: nil,
                  content_type: "application/json", binary_parts: {}, retry_safe: false, idempotency_key: nil,
                  if_match: nil, if_none_match: nil, response: :model, accept: nil, pagination: nil,
                  request_options: {}, &on_chunk)
        options = Config.check_request_options(request_options)
        conditional = Conditional.headers(if_match:, if_none_match:)
        # One key per call, not per attempt, so every retry and the 401
        # replay is recognised as the same request.
        key = options.fetch(:idempotency_key) { SecureRandom.uuid if idempotency_key == :required }
        encoded, encoded_type = encode(body, content_type, binary_parts)
        request = {
          method:,
          path: expand(path, path_params),
          query: Values.write(nil, query),
          headers: request_headers(conditional, accept, encoded_type, key, options.fetch(:headers, {})),
          body: encoded,
          timeout: options[:timeout],
        }
        policy = Retries::Policy.new(retry_safe: retry_safe?(method, retry_safe, key),
                                     max_retries: options.fetch(:max_retries, @connection.config.max_retries))
        return read_page(request, policy, model, pagination) if response == :page
        return download(request, policy, accept, on_chunk) if on_chunk

        Responses.read(authorized(request, policy, not_modified: !if_none_match.nil?), response, model, accept)
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

      # Only a success of the promised type reaches the block, so no retried
      # attempt hands it a byte twice; once bytes have reached it, the call
      # ends rather than retry.
      def download(request, policy, accept, on_chunk)
        stream = lambda do |status, headers|
          on_chunk if (200..299).cover?(status) && Responses.media_type?(headers["content-type"], accept)
        end
        Responses.read(authorized(request.merge(stream:), policy), :streamed, nil, accept)
      rescue Connection::Interrupted => e
        raise e.error, cause: nil
      end

      def authorized(request, policy, not_modified: false)
        Retries.call(@connection, policy, map_error: Error.method(:from_response),
                                          replay: method(:invalidate_refused_token), not_modified:) do
          token = @token_provider.access_token(@connection)
          request.merge(headers: request[:headers].merge("authorization" => "Bearer #{token}"))
        end
      end

      # Only the token the API refused is dropped, so concurrent calls that
      # were refused together share one fresh token.
      def invalidate_refused_token(request)
        @token_provider.invalidate(request[:headers]["authorization"].delete_prefix("Bearer "))
      end

      def request_headers(conditional, accept, content_type, idempotency_key, extra)
        headers = conditional.dup
        headers["accept"] = "#{accept}, #{PROBLEM_JSON}" if accept
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
    end
  end
end
