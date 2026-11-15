# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "seat_order_created_next_action"

module TeachMeHipaa
  # A SeatOrderCreatedNextActionInvoice object.
  class SeatOrderCreatedNextActionInvoice < Model
    include SeatOrderCreatedNextAction

    field :type, "type"
    field :hosted_invoice_url, "hostedInvoiceUrl"
  end
end
