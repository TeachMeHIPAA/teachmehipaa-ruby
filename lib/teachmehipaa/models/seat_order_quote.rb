# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A SeatOrderQuote object.
  class SeatOrderQuote < Model
    # Seats quoted.
    field :quantity, "quantity"
    # Price per seat, in the currency's smallest unit.
    field :unit_amount, "unitAmount"
    # Three-letter ISO currency code, lowercase.
    field :currency, "currency"
    # Price before tax.
    field :subtotal, "subtotal"
    # Always `null`: tax is calculated at payment.
    field :tax, "tax"
    # The quoted total.
    field :total, "total"
    # When the quote expires, 15 minutes after it was made.
    field :quote_expires_at, "quoteExpiresAt", type: :time
  end
end
