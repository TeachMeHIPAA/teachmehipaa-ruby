# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A PaymentMethodSetup object.
  class PaymentMethodSetup < Model
    # The Stripe-hosted page to send the buyer to.
    field :url, "url"
  end
end
