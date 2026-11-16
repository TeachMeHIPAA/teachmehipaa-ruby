# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "event"

module TeachMeHipaa
  # An EventSeatFreed object.
  class EventSeatFreed < Model
    include Event

    # @return [String]
    field :event_id, "eventId"
    # @return [String]
    field :event_type, "eventType"
    # @return [String]
    field :org_id, "orgId"
    # @return [Time]
    field :occurred_at, "occurredAt", type: :time
    # @return [Hash{String => Object}]
    field :data, "data"
  end
end
