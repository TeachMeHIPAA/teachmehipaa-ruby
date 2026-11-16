# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # The variant is picked by which field is present.
  module CancelEnrollmentResponse
    extend Union

    variants(
      {
        "refund" => "EnrollmentCancelRefunded",
      },
      fallback: "Enrollment",
    )
  end
end
