# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "event"
require_relative "learner_event_data"

module TeachMeHipaa
  # An EventLearnerRemoved object.
  class EventLearnerRemoved < Model
    include Event

    # @return [String]
    field :event_id, "eventId"
    # @return [String]
    field :event_type, "eventType"
    # @return [String]
    field :org_id, "orgId"
    # @return [Time]
    field :occurred_at, "occurredAt", type: :time
    # @return [LearnerEventData]
    field :data, "data", type: LearnerEventData
  end
end
