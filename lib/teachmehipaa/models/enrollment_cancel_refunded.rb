# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "cancel_enrollment_response"
require_relative "enrollment_cancel_refunded_refund"

module TeachMeHipaa
  # An EnrollmentCancelRefunded object.
  class EnrollmentCancelRefunded < Model
    include CancelEnrollmentResponse

    field :enrollment_id, "enrollmentId"
    field :subject_id, "subjectId"
    field :course_id, "courseId"
    field :org_id, "orgId"
    # See EnrollmentCancelRefundedStatus for known values; the API may send newer ones.
    field :status, "status"
    # See EnrollmentCancelRefundedEffectiveStatus for known values; the API may send newer ones.
    field :effective_status, "effectiveStatus"
    field :archived, "archived"
    field :cycle, "cycle"
    field :rev, "rev"
    field :invited_at, "invitedAt"
    field :started_at, "startedAt"
    field :completed_at, "completedAt"
    field :certified_at, "certifiedAt"
    field :expires_at, "expiresAt"
    field :certificate_id, "certificateId"
    field :refund, "refund", type: EnrollmentCancelRefundedRefund
  end
end
