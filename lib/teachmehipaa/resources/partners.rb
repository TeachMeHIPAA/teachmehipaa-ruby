# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.partners+.
    class Partners < Core::Resource
      attr_reader :organizations

      def initialize(requestor)
        super
        @organizations = PartnerOrganizations.new(requestor)
      end

      # Retrieve your partner account
      #
      # Retrieves your partner account, including how many organizations you can create. Requires
      # the `partner:orgs:read` scope.
      def retrieve(partner_id, request_options: {})
        request(
          method: "GET",
          path: "/partners/{partnerId}",
          path_params: { partnerId: partner_id },
          retry_safe: true,
          model: Partner,
          request_options:,
        )
      end
    end
  end
end
