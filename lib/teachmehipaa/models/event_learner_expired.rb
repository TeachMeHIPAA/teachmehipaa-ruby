# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "event"
require_relative "learner_event_data"

module TeachMeHipaa
  # An EventLearnerExpired object.
  class EventLearnerExpired < Model
    include Event

    field :event_id, "eventId"
    field :event_type, "eventType"
    field :org_id, "orgId"
    field :occurred_at, "occurredAt", type: :time
    field :data, "data", type: LearnerEventData
  end
end
