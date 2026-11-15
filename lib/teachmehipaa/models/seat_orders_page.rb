# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "seat_order"

module TeachMeHipaa
  # A SeatOrdersPage object.
  class SeatOrdersPage < Model
    field :items, "items", type: [SeatOrder]
    field :next_cursor, "nextCursor"
  end
end
