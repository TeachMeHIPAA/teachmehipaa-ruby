# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "seat_order_create_request_payment"

module TeachMeHipaa
  # A SeatOrderCreateRequestPaymentHostedCheckout object.
  class SeatOrderCreateRequestPaymentHostedCheckout < Model
    include SeatOrderCreateRequestPayment

    # No reader: +method+ is already a Ruby method. Read it with #[].
    field :method, "method", reader: false
    field :return_url, "returnUrl"
  end
end
