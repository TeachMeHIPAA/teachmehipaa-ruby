# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "billing_payment_method_default_payment_method"

module TeachMeHipaa
  # A BillingPaymentMethod object.
  class BillingPaymentMethod < Model
    # The saved card's brand, last four digits, expiry and id, or `null` when none is saved.
    field :default_payment_method, "defaultPaymentMethod", type: BillingPaymentMethodDefaultPaymentMethod
    # Whether a `saved_payment_method` order would charge it now.
    field :chargeable, "chargeable"
  end
end
