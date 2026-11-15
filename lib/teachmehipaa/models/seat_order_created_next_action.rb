# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Where to send the buyer next: a checkout `url` to redirect to, or a hosted invoice.
  #
  # Tell the variants apart by +type+ or by class. New variants may be added; handle ones you don't
  # recognize.
  module SeatOrderCreatedNextAction
    extend Union

    # A SeatOrderCreatedNextAction this library doesn't know yet. Its fields are all kept; read them
    # with #[] or #to_h.
    class Unknown < Model
      include SeatOrderCreatedNextAction
    end

    variants(
      {
        "invoice" => "SeatOrderCreatedNextActionInvoice",
        "redirect" => "SeatOrderCreatedNextActionRedirect",
      },
      property: "type",
      fallback: "SeatOrderCreatedNextAction::Unknown",
    )
  end
end
