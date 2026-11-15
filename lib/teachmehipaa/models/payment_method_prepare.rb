# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A PaymentMethodPrepare object.
  class PaymentMethodPrepare < Model
    # The Stripe SetupIntent.
    field :setup_intent_id, "setupIntentId"
    # Confirm the SetupIntent with Stripe.js using this secret.
    field :client_secret, "clientSecret"
    # The Stripe publishable key to load Stripe.js with.
    field :publishable_key, "publishableKey"
  end
end
