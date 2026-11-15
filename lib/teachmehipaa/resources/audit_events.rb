# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.audit_events+.
    class AuditEvents < Core::Resource
      # List all audit events
      #
      # Returns a list of the organization's audit events, newest first. Filter by `type`,
      # `transition`, `subjectId`, or a `since` and `until` range.
      def list(limit: nil, cursor: nil, type: nil, transition: nil, subject_id: nil, since: nil, until: nil,
               request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/audit-events",
          query: { limit:, cursor:, type:, transition:, subjectId: subject_id, since:,
                   until: binding.local_variable_get(:until) },
          retry_safe: true,
          response: :page,
          model: AuditEvent,
          request_options:,
        )
      end
    end
  end
end
