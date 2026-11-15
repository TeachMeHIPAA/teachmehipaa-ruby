# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.seats+.
    class Seats < Core::Resource
      # Retrieve the seat inventory
      #
      # Retrieves how many seats the organization has, how many are assigned and how many are
      # available for new invites. Requires the `enrollments:read` scope.
      def retrieve(request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/seats",
          retry_safe: true,
          model: SeatsInventory,
          request_options:,
        )
      end
    end
  end
end
