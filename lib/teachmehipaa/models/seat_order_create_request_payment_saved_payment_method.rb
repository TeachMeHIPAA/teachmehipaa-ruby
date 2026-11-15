# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "seat_order_create_request_payment"

module TeachMeHipaa
  # A SeatOrderCreateRequestPaymentSavedPaymentMethod object.
  class SeatOrderCreateRequestPaymentSavedPaymentMethod < Model
    include SeatOrderCreateRequestPayment

    # No reader: +method+ is already a Ruby method. Read it with #[].
    field :method, "method", reader: false
    field :return_url, "returnUrl"
    field :payment_method_id, "paymentMethodId"
    field :expected_total, "expectedTotal"
    field :currency, "currency"
  end
end
