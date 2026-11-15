# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "event"
require_relative "seat_order_event_data"

module TeachMeHipaa
  # An EventSeatOrderExpired object.
  class EventSeatOrderExpired < Model
    include Event

    field :event_id, "eventId"
    field :event_type, "eventType"
    field :org_id, "orgId"
    field :occurred_at, "occurredAt", type: :time
    field :data, "data", type: SeatOrderEventData
  end
end
