# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Tell the variants apart by +event_type+ or by class. New variants may be added; handle ones you
  # don't recognize.
  module Event
    extend Union

    variants(
      {
        "certificate.revoked" => "EventCertificateRevoked",
        "enrollment.certified" => "EventEnrollmentCertified",
        "invite.bounced" => "EventInviteBounced",
        "learner.certified" => "EventLearnerCertified",
        "learner.expired" => "EventLearnerExpired",
        "learner.expiring" => "EventLearnerExpiring",
        "learner.invited" => "EventLearnerInvited",
        "learner.removed" => "EventLearnerRemoved",
        "learner.started" => "EventLearnerStarted",
        "seat.consumed" => "EventSeatConsumed",
        "seat.freed" => "EventSeatFreed",
        "seat_order.expired" => "EventSeatOrderExpired",
        "seat_order.failed" => "EventSeatOrderFailed",
        "seat_order.paid" => "EventSeatOrderPaid",
        "seats.low" => "EventSeatsLow",
      },
      property: "eventType",
      fallback: "UnknownEvent",
    )
  end
end
