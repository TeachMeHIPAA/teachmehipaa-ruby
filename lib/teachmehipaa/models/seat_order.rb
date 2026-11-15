# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "seat_order_failure"

module TeachMeHipaa
  # A SeatOrder object.
  class SeatOrder < Model
    # Unique identifier for the seat order.
    field :seat_order_id, "seatOrderId"
    # The organization's id.
    field :org_id, "orgId"
    # Seats ordered.
    field :quantity, "quantity"
    # Price per seat, in the currency's smallest unit.
    field :unit_amount, "unitAmount"
    # Three-letter ISO currency code, lowercase.
    field :currency, "currency"
    # The order total, in the currency's smallest unit.
    field :total, "total"
    # `hosted_checkout`, `saved_payment_method` or `invoice`.
    #
    # See SeatOrderPaymentMethod for known values; the API may send newer ones.
    field :payment_method, "paymentMethod"
    # `requires_action`, `processing`, `invoiced`, `paid`, `failed`, `expired` or `refunded`.
    #
    # See SeatOrderStatus for known values; the API may send newer ones.
    field :status, "status"
    # Seats granted so far.
    field :seats_granted, "seatsGranted"
    # Seats refunded through support.
    field :seats_refunded, "seatsRefunded"
    # Why the order failed, with Stripe's decline code when there is one.
    field :failure, "failure", type: SeatOrderFailure
    # The API client that placed the order, if one did.
    field :client_id, "clientId"
    # Your own reference for the order.
    field :client_reference, "clientReference"
    # The Stripe checkout session, for a hosted checkout.
    field :checkout_id, "checkoutId"
    # When it was created (ISO 8601).
    field :created_at, "createdAt", type: :time
    # When it last changed.
    field :updated_at, "updatedAt", type: :time
    # The resource's revision. Its strong `ETag` is derived from it.
    field :rev, "rev"
  end
end
