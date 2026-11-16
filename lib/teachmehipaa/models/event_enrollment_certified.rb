# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "enrollment_certified_event_data"
require_relative "event"

module TeachMeHipaa
  # An EventEnrollmentCertified object.
  class EventEnrollmentCertified < Model
    include Event

    # @return [String]
    field :event_id, "eventId"
    # @return [String]
    field :event_type, "eventType"
    # @return [String]
    field :org_id, "orgId"
    # @return [Time]
    field :occurred_at, "occurredAt", type: :time
    # @return [EnrollmentCertifiedEventData]
    field :data, "data", type: EnrollmentCertifiedEventData
  end
end
