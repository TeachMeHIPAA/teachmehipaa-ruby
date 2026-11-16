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
      #
      # Needs the +audit:read+ Scope.
      #
      # @param limit [Integer, nil] How many objects to return, between 1 and 100. Defaults to 20.
      # @param cursor [String, nil] The `nextCursor` from the previous page.
      # @param type [String, Symbol, nil] Filter to one audit-event family.
      # @param transition [String, Symbol, nil] Filter to one lifecycle transition.
      # @param subject_id [String, nil] Filter to one member (canonical subject id).
      # @param since [Time, String, nil] Inclusive lower bound on `at` (ISO-8601 instant).
      # @param until [Time, String, nil] Inclusive upper bound on `at` (ISO-8601 instant).
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Page<AuditEvent>]
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
          pagination: { style: :cursor, cursor_param: "cursor" },
          request_options:,
        )
      end
    end
  end
end
