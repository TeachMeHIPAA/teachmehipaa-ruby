# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "cancel_enrollment_response"

module TeachMeHipaa
  # An Enrollment object.
  class Enrollment < Model
    include CancelEnrollmentResponse

    # Unique identifier for the enrollment.
    field :enrollment_id, "enrollmentId"
    # The learner's member id.
    field :subject_id, "subjectId"
    # The course.
    field :course_id, "courseId"
    # The organization's id.
    field :org_id, "orgId"
    # The stored lifecycle state: `INVITED`, `EMAIL_BOUNCED`, `STARTED`, `ASSESSMENT_IN_PROGRESS`,
    # `CERTIFIED` or `CANCELLED`.
    #
    # See EnrollmentStatus for known values; the API may send newer ones.
    field :status, "status"
    # The status to display. Adds `EXPIRING`, `EXPIRED` and `ARCHIVED`, derived when you read it.
    #
    # See EnrollmentEffectiveStatus for known values; the API may send newer ones.
    field :effective_status, "effectiveStatus"
    # Whether the enrollment is archived.
    field :archived, "archived"
    # The certification cycle, starting at 0. Renewing adds one.
    field :cycle, "cycle"
    # The resource's revision. Its strong `ETag` is derived from it.
    field :rev, "rev"
    # When the learner was invited (ISO 8601).
    field :invited_at, "invitedAt"
    # When the learner started.
    field :started_at, "startedAt"
    # When the learner completed the course.
    field :completed_at, "completedAt"
    # When the learner was certified.
    field :certified_at, "certifiedAt"
    # When the certification expires.
    field :expires_at, "expiresAt"
    # The certificate issued for this cycle, if any.
    field :certificate_id, "certificateId"
  end
end
