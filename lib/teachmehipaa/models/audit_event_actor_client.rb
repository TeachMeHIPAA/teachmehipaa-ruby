# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "audit_event_actor"

module TeachMeHipaa
  # An AuditEventActorClient object.
  class AuditEventActorClient < Model
    include AuditEventActor

    field :type, "type"
    field :client_id, "clientId"
  end
end
