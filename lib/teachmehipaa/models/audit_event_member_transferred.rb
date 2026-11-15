# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "audit_event"
require_relative "audit_event_actor"

module TeachMeHipaa
  # An AuditEventMemberTransferred object.
  class AuditEventMemberTransferred < Model
    include AuditEvent

    field :event_id, "eventId"
    field :at, "at"
    field :type, "type"
    field :actor_subject_id, "actorSubjectId"
    field :actor, "actor", type: AuditEventActor
    field :subject_id, "subjectId"
    field :target_org_id, "targetOrgId"
  end
end
