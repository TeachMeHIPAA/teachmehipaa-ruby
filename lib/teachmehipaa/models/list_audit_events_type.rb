# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module ListAuditEventsType
    ENROLLMENT_TRANSITION = "enrollment.transition"
    ORGANIZATION_UPDATED = "organization.updated"
    ORGANIZATION_CLOSED = "organization.closed"
    ORGANIZATION_REOPENED = "organization.reopened"
    MEMBER_ROLE_CHANGED = "member.role_changed"
    MEMBER_TRANSFERRED = "member.transferred"
    MEMBER_REMOVED = "member.removed"
    CERTIFICATE_ISSUED = "certificate.issued"
    CERTIFICATE_REVOKED = "certificate.revoked"
    SEAT_GRANTED = "seat.granted"
    API_CLIENT_CREATED = "api_client.created"
    API_CLIENT_SECRET_ROTATED = "api_client.secret_rotated"
    API_CLIENT_REVOKED = "api_client.revoked"
    LEARNER_UPDATED = "learner.updated"
    LEARNER_LAUNCH_LINK_CREATED = "learner.launch_link_created"
    API_CLIENT_UPDATED = "api_client.updated"
  end
end
