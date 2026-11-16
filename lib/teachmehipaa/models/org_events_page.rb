# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "event"

module TeachMeHipaa
  # An OrgEventsPage object.
  class OrgEventsPage < Model
    # @return [Array<Event>]
    field :items, "items", type: [Event]
    # @return [String, nil]
    field :next_cursor, "nextCursor"
  end
end
