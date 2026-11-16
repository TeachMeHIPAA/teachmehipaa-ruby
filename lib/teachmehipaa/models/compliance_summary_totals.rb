# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Learners by status: `learners`, `compliant`, `expiringSoon`, `expired`, `inProgress`,
  # `notStarted` and `inviteBounced`.
  class ComplianceSummaryTotals < Model
    # @return [Integer]
    field :learners, "learners"
    # @return [Integer]
    field :compliant, "compliant"
    # @return [Integer]
    field :expiring_soon, "expiringSoon"
    # @return [Integer]
    field :expired, "expired"
    # @return [Integer]
    field :in_progress, "inProgress"
    # @return [Integer]
    field :not_started, "notStarted"
    # @return [Integer]
    field :invite_bounced, "inviteBounced"
  end
end
