# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An EnrollmentCancelRequest object.
  class EnrollmentCancelRequest < Model
    # Refund the seat to the card that paid for it instead of returning it to the pool. Defaults to
    # `false`.
    field :refund, "refund"
  end
end
