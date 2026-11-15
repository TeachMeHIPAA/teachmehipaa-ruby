# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A SeatOrderEventData object.
  class SeatOrderEventData < Model
    field :seat_order_id, "seatOrderId"
    field :quantity, "quantity"
    # See SeatOrderEventDataStatus for known values; the API may send newer ones.
    field :status, "status"
  end
end
