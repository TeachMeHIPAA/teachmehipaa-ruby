# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "audit_event"
require_relative "audit_event_actor"

module TeachMeHipaa
  # An AuditEventOauthGrantCreated object.
  class AuditEventOauthGrantCreated < Model
    include AuditEvent

    field :event_id, "eventId"
    field :at, "at"
    field :type, "type"
    field :actor_subject_id, "actorSubjectId"
    field :actor, "actor", type: AuditEventActor
    field :app_id, "appId"
    field :grant_id, "grantId"
    # See AuditEventOauthGrantCreatedScopesItem for known values; the API may send newer ones.
    field :scopes, "scopes"
  end
end
