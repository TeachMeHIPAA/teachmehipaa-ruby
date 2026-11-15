# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.seat_orders+.
    class SeatOrders < Core::Resource
      # Create a seat order
      #
      # Buys seats at list price. Pay with a Stripe-hosted checkout, the organization's saved card,
      # or an invoice when it's enabled. Send the `expectedTotal` and `currency` from the quote you
      # showed the buyer: if the price changed, nothing is charged. Seats are granted once payment
      # succeeds. Requires the `seats:purchase` or `billing:write` scope.
      def create(quantity:, payment:, client_reference: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/seat-orders",
          body: SeatOrderCreateRequest.to_wire({ quantity:, payment:, client_reference: }.compact),
          retry_safe: true,
          idempotency_key: :required,
          model: SeatOrderCreated,
          request_options:,
        )
      end

      # List all seat orders
      #
      # Returns a list of the organization's seat orders, oldest first. Requires the
      # `seats:purchase` or `billing:write` scope.
      def list(limit: nil, cursor: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/seat-orders",
          query: { limit:, cursor: },
          retry_safe: true,
          response: :page,
          model: SeatOrder,
          request_options:,
        )
      end

      # Quote a seat order
      #
      # Gets the list price for a number of seats in the organization's currency, before tax. The
      # quote is for display and expires after 15 minutes. Requires the `seats:purchase` or
      # `billing:write` scope.
      def quote(quantity:, currency: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/seat-orders:quote",
          body: SeatOrderQuoteRequest.to_wire({ quantity:, currency: }.compact),
          retry_safe: true,
          model: SeatOrderQuote,
          request_options:,
        )
      end

      # Retrieve a seat order
      #
      # Retrieves a seat order, its status and the seats it granted. Requires the `seats:purchase`
      # or `billing:write` scope.
      def retrieve(seat_order_id, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/seat-orders/{seatOrderId}",
          path_params: { seatOrderId: seat_order_id },
          retry_safe: true,
          model: SeatOrder,
          request_options:,
        )
      end
    end
  end
end
