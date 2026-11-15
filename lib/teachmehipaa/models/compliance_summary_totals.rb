# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Learners by status: `learners`, `compliant`, `expiringSoon`, `expired`, `inProgress`,
  # `notStarted` and `inviteBounced`.
  class ComplianceSummaryTotals < Model
    field :learners, "learners"
    field :compliant, "compliant"
    field :expiring_soon, "expiringSoon"
    field :expired, "expired"
    field :in_progress, "inProgress"
    field :not_started, "notStarted"
    field :invite_bounced, "inviteBounced"
  end
end
