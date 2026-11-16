# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "cancel_enrollment_response"
require_relative "enrollment_cancel_refunded_refund"

module TeachMeHipaa
  # An EnrollmentCancelRefunded object.
  class EnrollmentCancelRefunded < Model
    include CancelEnrollmentResponse

    # @return [String]
    field :enrollment_id, "enrollmentId"
    # @return [String]
    field :subject_id, "subjectId"
    # @return [String]
    field :course_id, "courseId"
    # @return [String]
    field :org_id, "orgId"
    # See EnrollmentCancelRefundedStatus for known values; the API may send newer ones.
    #
    # @return [String]
    field :status, "status"
    # See EnrollmentCancelRefundedEffectiveStatus for known values; the API may send newer ones.
    #
    # @return [String]
    field :effective_status, "effectiveStatus"
    # @return [Boolean]
    field :archived, "archived"
    # @return [Integer]
    field :cycle, "cycle"
    # @return [Integer]
    field :rev, "rev"
    # @return [String, nil]
    field :invited_at, "invitedAt"
    # @return [String, nil]
    field :started_at, "startedAt"
    # @return [String, nil]
    field :completed_at, "completedAt"
    # @return [String, nil]
    field :certified_at, "certifiedAt"
    # @return [String, nil]
    field :expires_at, "expiresAt"
    # @return [String, nil]
    field :certificate_id, "certificateId"
    # @return [EnrollmentCancelRefundedRefund]
    field :refund, "refund", type: EnrollmentCancelRefundedRefund
  end
end
