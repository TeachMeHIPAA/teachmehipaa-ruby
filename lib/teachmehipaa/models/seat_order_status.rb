# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # `requires_action`, `processing`, `invoiced`, `paid`, `failed`, `expired` or `refunded`.
  #
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module SeatOrderStatus
    REQUIRES_ACTION = "requires_action"
    PROCESSING = "processing"
    INVOICED = "invoiced"
    PAID = "paid"
    FAILED = "failed"
    EXPIRED = "expired"
    REFUNDED = "refunded"
  end
end
