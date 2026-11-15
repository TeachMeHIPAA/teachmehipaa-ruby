# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.payment_method+.
    class PaymentMethod < Core::Resource
      # Finish saving a card
      #
      # Makes the card from a confirmed SetupIntent the organization's default for seat orders. Safe
      # to repeat. Requires the `seats:purchase` or `billing:write` scope.
      def confirm(setup_intent_id:, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/billing/payment-method:confirm",
          body: PaymentMethodConfirmRequest.to_wire({ setup_intent_id: }),
          retry_safe: true,
          model: BillingPaymentMethod,
          request_options:,
        )
      end

      # Delete the saved card
      #
      # Removes the saved card. Seats already bought aren't affected. Requires the `seats:purchase`
      # or `billing:write` scope.
      def delete(request_options: {})
        request(
          method: "DELETE",
          path: "/organizations/{orgId}/billing/payment-method",
          response: :empty,
          request_options:,
        )
      end

      # Start saving a card
      #
      # Creates a Stripe SetupIntent for a card form in your own page. Confirm it with Stripe.js,
      # then finish saving the card. Saving a card never charges it. Requires the `seats:purchase`
      # or `billing:write` scope.
      def prepare(request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/billing/payment-method:prepare",
          retry_safe: true,
          idempotency_key: :required,
          model: PaymentMethodPrepare,
          request_options:,
        )
      end

      # Retrieve the saved card
      #
      # Retrieves the card seat orders charge: its brand, last four digits and expiry. Card numbers
      # are never returned. Requires the `seats:purchase` or `billing:write` scope.
      def retrieve(request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/billing/payment-method",
          retry_safe: true,
          model: BillingPaymentMethod,
          request_options:,
        )
      end

      # Save a card with Checkout
      #
      # Creates a Stripe-hosted page where the buyer saves the card that seat orders charge. The
      # card becomes the organization's default. Requires the `seats:purchase` or `billing:write`
      # scope.
      def setup(return_url:, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/billing/payment-method:setup",
          body: PaymentMethodSetupRequest.to_wire({ return_url: }),
          retry_safe: true,
          idempotency_key: :required,
          model: PaymentMethodSetup,
          request_options:,
        )
      end
    end
  end
end
