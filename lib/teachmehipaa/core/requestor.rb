# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # The request pipeline behind every resource method: binds the
    # Organization, authorizes, attaches the Idempotency-Key, sends with
    # retries and reads the response into a model.
    #
    # @api private
    class Requestor
      INTROSPECTION = { method: "GET", path: "/auth/introspection", headers: {} }.freeze
      ORG_PLACEHOLDER = "{orgId}"
      # Errors come as RFC 9457 problems whatever a download's own type.
      PROBLEM_JSON = "application/problem+json"
      NO_CREDENTIALS = "This client has no credentials; pass client_id and client_secret, or token_provider, " \
                       "to call methods that need an Access token."

      # One call as sent: the request (Connection#request's keyword
      # arguments), its retry policy, and whether it carries an Access token.
      Call = Data.define(:request, :policy, :authenticated)

      # A nil +token_provider+ is a client built without credentials: only
      # unauthenticated calls go out.
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
      # +idempotency_key+ (:required or nil) come from the IR; only
      # +retry_safe+ makes a call retryable, whatever key it carries.
      # +authenticated+ is false for the IR's +security: none+ operations,
      # which send no Access token.
      #
      # +if_match+ and +if_none_match+ are ETags for the conditional headers:
      # a String, or an object the client returned (its last response's
      # ETag).
      #
      # +response+ is the IR's response kind (see Responses::READERS): :model
      # (+model+ reads the body), :page (+model+ reads each item), :operation
      # (+model+, an Operation class, reads the body and polls through this
      # requestor), :write_result, :empty, or :binary (the body must be of
      # media type +accept+). A :page also takes the IR's +pagination+:
      # +{ style: :cursor | :after, cursor_param: }+. A :binary call given a
      # block streams the body to it instead.
      def request(method:, path:, model: nil, path_params: {}, query: {}, body: nil,
                  content_type: "application/json", binary_parts: {}, retry_safe: false, idempotency_key: nil,
                  authenticated: true, if_match: nil, if_none_match: nil, response: :model, accept: nil,
                  pagination: nil, request_options: {}, &on_chunk)
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
          headers: request_headers(conditional, accept, encoded_type, key, options),
          body: encoded,
          timeout: options[:timeout],
        }
        policy = Retries::Policy.for(method, retry_safe:, max_retries: options.fetch(:max_retries, config.max_retries))
        call = Call.new(request:, policy:, authenticated:)
        reading = Responses::Reading.new(model:, accept:, fetch_next: nil, requestor: self)
        return download(call, reading, on_chunk) if on_chunk

        read(call, response, reading, pagination, not_modified: !if_none_match.nil?)
      end

      def config = @connection.config

      private

      # A page's next page is this call again with only the cursor parameter
      # changed, so filters, the limit and request options carry over.
      def read(call, kind, reading, pagination, not_modified: false)
        fetch_next = pagination && lambda do |page|
          position = Pagination.position(pagination.fetch(:style), page)
          query = call.request[:query].merge(pagination.fetch(:cursor_param) => position)
          read(call.with(request: call.request.merge(query:)), kind, reading, pagination)
        end
        Responses.read(authorized(call, not_modified:), kind, reading.with(fetch_next:))
      end

      # Only a success of the promised type reaches the block, so no retried
      # attempt hands it a byte twice; once bytes have reached it, the call
      # ends rather than retry.
      def download(call, reading, on_chunk)
        stream = lambda do |status, headers|
          on_chunk if Responses.success?(status) && Responses.media_type?(headers["content-type"], reading.accept)
        end
        Responses.read(authorized(call.with(request: call.request.merge(stream:))), :streamed, reading)
      rescue Connection::Interrupted => e
        raise e.error, cause: nil
      end

      def authorized(call, not_modified: false)
        raise AuthenticationError, NO_CREDENTIALS if call.authenticated && @token_provider.nil?

        replay = method(:replay_with_fresh_token?) if call.authenticated
        Retries.call(@connection, call.policy, map_error: Error.method(:from_response), replay:, not_modified:) do
          next call.request unless call.authenticated

          token = @token_provider.access_token(@connection)
          call.request.merge(headers: call.request[:headers].merge("authorization" => "Bearer #{token}"))
        end
      end

      # Only the token the API refused is dropped, so concurrent calls that
      # were refused together share one fresh token. A provider that can't
      # renew (a static token) hands back the same token, which the API would
      # only refuse again, so that call isn't replayed.
      def replay_with_fresh_token?(request)
        refused = request[:headers]["authorization"].delete_prefix("Bearer ")
        @token_provider.invalidate(refused)
        @token_provider.access_token(@connection) != refused
      end

      def request_headers(conditional, accept, content_type, idempotency_key, options)
        headers = conditional.dup
        headers["accept"] = "#{accept}, #{PROBLEM_JSON}" if accept
        headers["content-type"] = content_type if content_type
        headers["idempotency-key"] = idempotency_key if idempotency_key
        headers.merge({ "x-request-id" => options[:request_id] }.compact, options.fetch(:headers, {}))
      end

      def organization_id
        @organization_lock.synchronize do
          @organization_id ||= introspect_organization_id
        end
      end

      def introspect_organization_id
        policy = Retries::Policy.new(retry_safe: true, max_retries: config.max_retries)
        response = authorized(Call.new(request: INTROSPECTION, policy:, authenticated: true))
        organization_id = Json.success_body(response)["orgId"]
        return organization_id if organization_id.is_a?(String)

        raise Error.new(
          "The Access token is not bound to an Organization. Pass organization_id: when you create the client.",
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
