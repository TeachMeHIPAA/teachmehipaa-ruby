# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An EnrollmentCancelRefundedRefund object.
  class EnrollmentCancelRefundedRefund < Model
    # @return [String]
    field :refund_id, "refundId"
    # @return [Integer]
    field :amount_cents, "amountCents"
    # @return [String]
    field :currency, "currency"
  end
end
