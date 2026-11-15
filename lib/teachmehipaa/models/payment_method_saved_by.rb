# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Tell the variants apart by +type+ or by class. New variants may be added; handle ones you don't
  # recognize.
  module PaymentMethodSavedBy
    extend Union

    # A PaymentMethodSavedBy this library doesn't know yet. Its fields are all kept; read them with
    # #[] or #to_h.
    class Unknown < Model
      include PaymentMethodSavedBy
    end

    variants(
      {
        "api_client" => "PaymentMethodSavedByApiClient",
        "user" => "PaymentMethodSavedByUser",
      },
      property: "type",
      fallback: "PaymentMethodSavedBy::Unknown",
    )
  end
end
