# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "audit_event_actor"

module TeachMeHipaa
  # An AuditEventActorAgent object.
  class AuditEventActorAgent < Model
    include AuditEventActor

    # @return [String]
    field :type, "type"
    # @return [String]
    field :agent_id, "agentId"
  end
end
