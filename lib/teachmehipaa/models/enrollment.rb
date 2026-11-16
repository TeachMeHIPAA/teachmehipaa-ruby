# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "cancel_enrollment_response"

module TeachMeHipaa
  # An Enrollment object.
  class Enrollment < Model
    include CancelEnrollmentResponse

    # Unique identifier for the enrollment.
    #
    # @return [String]
    field :enrollment_id, "enrollmentId"
    # The learner's member id.
    #
    # @return [String]
    field :subject_id, "subjectId"
    # The course.
    #
    # @return [String]
    field :course_id, "courseId"
    # The organization's id.
    #
    # @return [String]
    field :org_id, "orgId"
    # The stored lifecycle state: `INVITED`, `EMAIL_BOUNCED`, `STARTED`, `ASSESSMENT_IN_PROGRESS`,
    # `CERTIFIED` or `CANCELLED`.
    #
    # See EnrollmentStatus for known values; the API may send newer ones.
    #
    # @return [String]
    field :status, "status"
    # The status to display. Adds `EXPIRING`, `EXPIRED` and `ARCHIVED`, derived when you read it.
    #
    # See EnrollmentEffectiveStatus for known values; the API may send newer ones.
    #
    # @return [String]
    field :effective_status, "effectiveStatus"
    # Whether the enrollment is archived.
    #
    # @return [Boolean]
    field :archived, "archived"
    # The certification cycle, starting at 0. Renewing adds one.
    #
    # @return [Integer]
    field :cycle, "cycle"
    # The resource's revision. Its strong `ETag` is derived from it.
    #
    # @return [Integer]
    field :rev, "rev"
    # When the learner was invited (ISO 8601).
    #
    # @return [String, nil]
    field :invited_at, "invitedAt"
    # When the learner started.
    #
    # @return [String, nil]
    field :started_at, "startedAt"
    # When the learner completed the course.
    #
    # @return [String, nil]
    field :completed_at, "completedAt"
    # When the learner was certified.
    #
    # @return [String, nil]
    field :certified_at, "certifiedAt"
    # When the certification expires.
    #
    # @return [String, nil]
    field :expires_at, "expiresAt"
    # The certificate issued for this cycle, if any.
    #
    # @return [String, nil]
    field :certificate_id, "certificateId"
  end
end
