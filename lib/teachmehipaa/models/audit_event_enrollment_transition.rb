# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "audit_event"

module TeachMeHipaa
  # An AuditEventEnrollmentTransition object.
  class AuditEventEnrollmentTransition < Model
    include AuditEvent

    # @return [String]
    field :event_id, "eventId"
    # @return [String]
    field :at, "at"
    # @return [String]
    field :type, "type"
    # See AuditEventEnrollmentTransitionTransition for known values; the API may send newer ones.
    #
    # @return [String]
    field :transition, "transition"
    # @return [String]
    field :subject_id, "subjectId"
    # @return [String]
    field :course_id, "courseId"
    # See AuditEventEnrollmentTransitionStatusFrom for known values; the API may send newer ones.
    #
    # @return [String]
    field :status_from, "statusFrom"
    # See AuditEventEnrollmentTransitionStatusTo for known values; the API may send newer ones.
    #
    # @return [String]
    field :status_to, "statusTo"
    # @return [Boolean]
    field :archived_from, "archivedFrom"
    # @return [Boolean]
    field :archived_to, "archivedTo"
    # @return [Integer]
    field :rev, "rev"
  end
end
