# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "enrollment_certified_event_data"
require_relative "event"

module TeachMeHipaa
  # An EventEnrollmentCertified object.
  class EventEnrollmentCertified < Model
    include Event

    field :event_id, "eventId"
    field :event_type, "eventType"
    field :org_id, "orgId"
    field :occurred_at, "occurredAt", type: :time
    field :data, "data", type: EnrollmentCertifiedEventData
  end
end
