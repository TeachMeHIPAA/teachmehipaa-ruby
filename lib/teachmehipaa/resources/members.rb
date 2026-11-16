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
      #
      # Needs the +members:read+ Scope.
      #
      # @param limit [Integer, nil] How many objects to return, between 1 and 1000. Defaults to
      #   20.
      # @param cursor [String, nil] The `nextCursor` from the previous page.
      # @param include [String, nil] Opt-in, comma-separated. With `enrollmentSubject`, a member
      #   whose `subjectId` is null carries `enrollmentSubjectId`: the subject their email resolves
      #   to (a never-signed-in invitee), or null when none. Use it only to match the member to
      #   Enrollments; it is not an address for member routes. With `holdsInvitation`, each learner
      #   carries `holdsInvitation`: whether the organization has an invitation for their email or a
      #   Seat bound to them. Each key is omitted when its lookup failed.
      # @param role [String, Symbol, nil] Only admins (paginated).
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Page<MemberListItem>]
      def list(limit: nil, cursor: nil, include: nil, role: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/members",
          query: { limit:, cursor:, include:, role: },
          retry_safe: true,
          response: :page,
          model: MemberListItem,
          pagination: { style: :cursor, cursor_param: "cursor" },
          request_options:,
        )
      end

      # Retrieve a member
      #
      # Retrieves a member of the organization.
      #
      # Needs the +members:read+ Scope.
      #
      # @param subject_id [String] The member's id.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Member]
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
