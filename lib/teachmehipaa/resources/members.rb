# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.members+.
    class Members < Core::Resource
      # List all members
      #
      # Returns a list of the organization's members, its admins and learners. Pass `role=admin` to
      # list only admins.
      def list(limit: nil, cursor: nil, include: nil, role: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/members",
          query: { limit:, cursor:, include:, role: },
          retry_safe: true,
          response: :page,
          model: MemberListItem,
          request_options:,
        )
      end

      # Retrieve a member
      #
      # Retrieves a member of the organization.
      def retrieve(subject_id, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/members/{subjectId}",
          path_params: { subjectId: subject_id },
          retry_safe: true,
          model: Member,
          request_options:,
        )
      end
    end
  end
end
