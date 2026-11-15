# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "seat_order_create_request_payment"

module TeachMeHipaa
  # A SeatOrderCreateRequest object.
  class SeatOrderCreateRequest < Model
    # Seats to buy.
    field :quantity, "quantity"
    # How to pay: `hosted_checkout` with a `returnUrl`, `saved_payment_method` with the card's
    # `paymentMethodId`, or `invoice`. A `returnUrl` must be https and on your API client's
    # allowlist.
    field :payment, "payment", type: SeatOrderCreateRequestPayment
    # Your own reference for the order.
    field :client_reference, "clientReference"
  end
end
