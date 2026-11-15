# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "event"

module TeachMeHipaa
  # An OrgEventsPage object.
  class OrgEventsPage < Model
    field :items, "items", type: [Event]
    field :next_cursor, "nextCursor"
  end
end
