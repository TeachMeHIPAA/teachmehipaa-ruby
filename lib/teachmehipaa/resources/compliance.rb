# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.compliance+.
    class Compliance < Core::Resource
      # Retrieve the compliance summary
      #
      # Counts the organization's learners in one course by status. Removed learners aren't counted.
      #
      # Needs the +compliance:read+ Scope.
      #
      # @param course_id [String, nil] The course. Defaults to the organization's default course.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [ComplianceSummary]
      def retrieve(course_id: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/compliance",
          query: { courseId: course_id },
          retry_safe: true,
          model: ComplianceSummary,
          request_options:,
        )
      end
    end
  end
end
