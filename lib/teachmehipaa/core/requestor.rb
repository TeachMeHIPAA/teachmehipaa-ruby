# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # The request pipeline behind every resource method: binds the
    # Organization, authorizes, sends and reads the response into a model.
    #
    # @api private
    class Requestor
      INTROSPECTION_PATH = "/auth/introspection"
      ORG_PLACEHOLDER = "{orgId}"
      REQUEST_OPTIONS = %i[headers timeout].freeze

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
      def request(method:, path:, model:, path_params: {}, query: {}, request_options: {})
        options = check_request_options(request_options)
        params = path_params.transform_keys(&:to_s)
        params["orgId"] = organization_id if path.include?(ORG_PLACEHOLDER)
        response = authorized(method:, path: expand(path, params), query:,
                              headers: options.fetch(:headers, {}), timeout: options[:timeout])
        model.new(Json.success_body(response), last_response: LastResponse.from(response))
      end

      private

      def authorized(method:, path:, query: {}, headers: {}, timeout: nil)
        token = @token_provider.access_token(@connection)
        @connection.request(
          method:, path:, query:, timeout:,
          headers: headers.merge("authorization" => "Bearer #{token}")
        )
      end

      def organization_id
        @organization_lock.synchronize do
          @organization_id ||= introspect_organization_id
        end
      end

      def introspect_organization_id
        response = authorized(method: "GET", path: INTROSPECTION_PATH)
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
        return options if unknown.empty?

        raise ArgumentError, "unknown request option(s): #{unknown.map(&:inspect).join(", ")}"
      end
    end
  end
end
