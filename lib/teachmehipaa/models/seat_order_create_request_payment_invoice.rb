# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "seat_order_create_request_payment"

module TeachMeHipaa
  # A SeatOrderCreateRequestPaymentInvoice object.
  class SeatOrderCreateRequestPaymentInvoice < Model
    include SeatOrderCreateRequestPayment

    # No reader: +method+ is already a Ruby method. Read it with #[].
    field :method, "method", reader: false
    field :days_until_due, "daysUntilDue"
  end
end
