# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "seat_order_created_failure"
require_relative "seat_order_created_next_action"

module TeachMeHipaa
  # A SeatOrderCreated object.
  class SeatOrderCreated < Model
    # Unique identifier for the seat order.
    field :seat_order_id, "seatOrderId"
    # The order's status.
    #
    # See SeatOrderCreatedStatus for known values; the API may send newer ones.
    field :status, "status"
    # Where to send the buyer next: a checkout `url` to redirect to, or a hosted invoice.
    field :next_action, "nextAction", type: SeatOrderCreatedNextAction
    # Why the payment failed, if it did.
    field :failure, "failure", type: SeatOrderCreatedFailure
  end
end
