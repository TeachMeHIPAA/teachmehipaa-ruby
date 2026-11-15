# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "compliance_summary_totals"

module TeachMeHipaa
  # A ComplianceSummary object.
  class ComplianceSummary < Model
    # When the counts were taken (ISO 8601).
    field :as_of, "asOf", type: :time
    # The course.
    field :course_id, "courseId"
    # Learners by status: `learners`, `compliant`, `expiringSoon`, `expired`, `inProgress`,
    # `notStarted` and `inviteBounced`.
    field :totals, "totals", type: ComplianceSummaryTotals
    # `compliant` divided by `learners`, or 0 with no learners.
    field :compliant_rate, "compliantRate"
  end
end
