# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.partners.organizations+.
    class PartnerOrganizations < Core::Resource
      # Create a customer organization
      #
      # Creates an organization for a customer with your app already connected, and emails its
      # administrator a link to sign in. The organization has no seats until seats are bought for
      # it. Requires the `partner:orgs:write` scope.
      def create(partner_id, name:, admin_email:, scopes:, admin_name: nil, request_options: {})
        request(
          method: "POST",
          path: "/partners/{partnerId}/organizations",
          path_params: { partnerId: partner_id },
          body: PartnerOrganizationCreate.to_wire({ name:, admin_email:, admin_name:, scopes: }.compact),
          retry_safe: true,
          idempotency_key: :required,
          model: PartnerOrganizationCreated,
          request_options:,
        )
      end

      # List all customer organizations
      #
      # Returns a list of the organizations you created. `grantActive` is `false` once a customer
      # disconnects your app. Requires the `partner:orgs:read` scope.
      def list(partner_id, limit: nil, cursor: nil, request_options: {})
        request(
          method: "GET",
          path: "/partners/{partnerId}/organizations",
          path_params: { partnerId: partner_id },
          query: { limit:, cursor: },
          retry_safe: true,
          response: :page,
          model: PartnerOrganization,
          pagination: { style: :cursor, cursor_param: "cursor" },
          request_options:,
        )
      end
    end
  end
end
