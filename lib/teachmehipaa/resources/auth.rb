# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.auth+.
    class Auth < Core::Resource
      # Retrieve the current token
      #
      # Describes the access token you call with: whether it belongs to an API client or a person,
      # its organization, its scopes and when it expires. Needs no scope.
      #
      # Works with any Access token, whatever its Scopes.
      #
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [TokenIntrospection]
      def introspect(request_options: {})
        request(
          method: "GET",
          path: "/auth/introspection",
          retry_safe: true,
          model: TokenIntrospection,
          request_options:,
        )
      end
    end
  end
end
