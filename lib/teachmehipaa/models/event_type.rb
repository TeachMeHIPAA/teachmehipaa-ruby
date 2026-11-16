# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module EventType
    ENROLLMENT_CERTIFIED = "enrollment.certified"
    SEAT_CONSUMED = "seat.consumed"
    SEAT_FREED = "seat.freed"
    LEARNER_INVITED = "learner.invited"
    LEARNER_STARTED = "learner.started"
    LEARNER_CERTIFIED = "learner.certified"
    LEARNER_EXPIRING = "learner.expiring"
    LEARNER_EXPIRED = "learner.expired"
    LEARNER_REMOVED = "learner.removed"
    INVITE_BOUNCED = "invite.bounced"
    CERTIFICATE_REVOKED = "certificate.revoked"
    SEATS_LOW = "seats.low"
  end
end
