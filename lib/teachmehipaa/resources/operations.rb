# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.operations+.
    class Operations < Core::Resource
      # Retrieve an operation
      #
      # Retrieves a bulk operation and its result. Operations are kept for 24 hours.
      def retrieve(operation_id, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/operations/{operationId}",
          path_params: { operationId: operation_id },
          retry_safe: true,
          response: :operation,
          model: Operation,
          request_options:,
        )
      end
    end
  end
end
