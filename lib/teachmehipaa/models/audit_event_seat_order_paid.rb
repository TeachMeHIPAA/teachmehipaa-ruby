# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "audit_event"
require_relative "audit_event_actor"

module TeachMeHipaa
  # An AuditEventSeatOrderPaid object.
  class AuditEventSeatOrderPaid < Model
    include AuditEvent

    field :event_id, "eventId"
    field :at, "at"
    field :actor_subject_id, "actorSubjectId"
    field :actor, "actor", type: AuditEventActor
    field :seat_order_id, "seatOrderId"
    field :quantity, "quantity"
    # See AuditEventPaymentMethod for known values; the API may send newer ones.
    field :payment_method, "paymentMethod"
    field :type, "type"
  end
end
