# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # How to pay: `hosted_checkout` with a `returnUrl`, `saved_payment_method` with the card's
  # `paymentMethodId`, or `invoice`. A `returnUrl` must be https and on your API client's allowlist.
  #
  # Tell the variants apart by +method+ or by class. New variants may be added; handle ones you
  # don't recognize.
  module SeatOrderCreateRequestPayment
    extend Union

    # A SeatOrderCreateRequestPayment this library doesn't know yet. Its fields are all kept; read
    # them with #[] or #to_h.
    class Unknown < Model
      include SeatOrderCreateRequestPayment
    end

    variants(
      {
        "hosted_checkout" => "SeatOrderCreateRequestPaymentHostedCheckout",
        "invoice" => "SeatOrderCreateRequestPaymentInvoice",
        "saved_payment_method" => "SeatOrderCreateRequestPaymentSavedPaymentMethod",
      },
      property: "method",
      fallback: "SeatOrderCreateRequestPayment::Unknown",
    )
  end
end
