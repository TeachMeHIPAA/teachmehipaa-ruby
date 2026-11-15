# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A PaymentMethodSetupRequest object.
  class PaymentMethodSetupRequest < Model
    # Where Stripe sends the buyer afterwards. Must be https and on your client's allowlist.
    field :return_url, "returnUrl"
  end
end
