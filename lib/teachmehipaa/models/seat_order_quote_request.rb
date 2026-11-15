# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A SeatOrderQuoteRequest object.
  class SeatOrderQuoteRequest < Model
    # Seats to quote.
    field :quantity, "quantity"
    # The currency you expect to be charged in. It must match the organization's.
    field :currency, "currency"
  end
end
