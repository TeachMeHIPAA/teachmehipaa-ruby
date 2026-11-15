# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "audit_event_actor"

module TeachMeHipaa
  # An AuditEventActorUser object.
  class AuditEventActorUser < Model
    include AuditEventActor

    field :type, "type"
    field :subject_id, "subjectId"
  end
end
