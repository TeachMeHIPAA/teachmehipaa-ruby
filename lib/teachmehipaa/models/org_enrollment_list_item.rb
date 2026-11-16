# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "org_enrollment_list_item_prior_certificate"

module TeachMeHipaa
  # An OrgEnrollmentListItem object.
  class OrgEnrollmentListItem < Model
    # @return [String]
    field :enrollment_id, "enrollmentId"
    # @return [String]
    field :subject_id, "subjectId"
    # @return [String]
    field :course_id, "courseId"
    # @return [String]
    field :org_id, "orgId"
    # See OrgEnrollmentListItemStatus for known values; the API may send newer ones.
    #
    # @return [String]
    field :status, "status"
    # See OrgEnrollmentListItemEffectiveStatus for known values; the API may send newer ones.
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
    # @return [OrgEnrollmentListItemPriorCertificate, nil]
    field :prior_certificate, "priorCertificate", type: OrgEnrollmentListItemPriorCertificate
  end
end
