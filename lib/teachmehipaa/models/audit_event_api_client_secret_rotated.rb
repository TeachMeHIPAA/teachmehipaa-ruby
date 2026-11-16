# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "audit_event"
require_relative "audit_event_actor"

module TeachMeHipaa
  # An AuditEventApiClientSecretRotated object.
  class AuditEventApiClientSecretRotated < Model
    include AuditEvent

    # @return [String]
    field :event_id, "eventId"
    # @return [String]
    field :at, "at"
    # @return [String]
    field :type, "type"
    # @return [String]
    field :actor_subject_id, "actorSubjectId"
    # @return [AuditEventActor]
    field :actor, "actor", type: AuditEventActor
    # @return [String]
    field :client_id, "clientId"
  end
end
