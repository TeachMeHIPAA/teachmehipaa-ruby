# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "payment_method_saved_by"

module TeachMeHipaa
  # A BillingPaymentMethodDefaultPaymentMethod object.
  class BillingPaymentMethodDefaultPaymentMethod < Model
    field :brand, "brand"
    field :last4, "last4"
    field :exp_month, "expMonth"
    field :exp_year, "expYear"
    field :payment_method_id, "paymentMethodId"
    field :saved_by, "savedBy", type: PaymentMethodSavedBy
    field :saved_at, "savedAt", type: :time
    field :expired, "expired"
  end
end
