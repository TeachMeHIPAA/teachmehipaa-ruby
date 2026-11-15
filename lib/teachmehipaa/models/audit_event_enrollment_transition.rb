# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "audit_event"

module TeachMeHipaa
  # An AuditEventEnrollmentTransition object.
  class AuditEventEnrollmentTransition < Model
    include AuditEvent

    field :event_id, "eventId"
    field :at, "at"
    field :type, "type"
    # See AuditEventEnrollmentTransitionTransition for known values; the API may send newer ones.
    field :transition, "transition"
    field :subject_id, "subjectId"
    field :course_id, "courseId"
    # See AuditEventEnrollmentTransitionStatusFrom for known values; the API may send newer ones.
    field :status_from, "statusFrom"
    # See AuditEventEnrollmentTransitionStatusTo for known values; the API may send newer ones.
    field :status_to, "statusTo"
    field :archived_from, "archivedFrom"
    field :archived_to, "archivedTo"
    field :rev, "rev"
  end
end
