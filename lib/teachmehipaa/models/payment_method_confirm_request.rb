# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A PaymentMethodConfirmRequest object.
  class PaymentMethodConfirmRequest < Model
    # The SetupIntent you confirmed with Stripe.js.
    field :setup_intent_id, "setupIntentId"
  end
end
