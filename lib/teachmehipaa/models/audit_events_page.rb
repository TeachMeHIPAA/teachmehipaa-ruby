# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "audit_event"

module TeachMeHipaa
  # An AuditEventsPage object.
  class AuditEventsPage < Model
    field :items, "items", type: [AuditEvent]
    field :next_cursor, "nextCursor"
  end
end
