# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "audit_event"
require_relative "audit_event_actor"

module TeachMeHipaa
  # An AuditEventMemberRoleChanged object.
  class AuditEventMemberRoleChanged < Model
    include AuditEvent

    field :event_id, "eventId"
    field :at, "at"
    field :type, "type"
    field :actor_subject_id, "actorSubjectId"
    field :actor, "actor", type: AuditEventActor
    field :subject_id, "subjectId"
    # See AuditEventMemberRoleChangedRoleFrom for known values; the API may send newer ones.
    field :role_from, "roleFrom"
    # See AuditEventMemberRoleChangedRoleTo for known values; the API may send newer ones.
    field :role_to, "roleTo"
  end
end
