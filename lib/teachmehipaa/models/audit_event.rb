# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Tell the variants apart by +type+ or by class. New variants may be added; handle ones you don't
  # recognize.
  module AuditEvent
    extend Union

    # An AuditEvent this library doesn't know yet. Its fields are all kept; read them with #[] or
    # #to_h.
    class Unknown < Model
      include AuditEvent
    end

    variants(
      {
        "api_client.created" => "AuditEventApiClientCreated",
        "api_client.revoked" => "AuditEventApiClientRevoked",
        "api_client.secret_rotated" => "AuditEventApiClientSecretRotated",
        "api_client.updated" => "AuditEventApiClientUpdated",
        "certificate.issued" => "AuditEventCertificateIssued",
        "certificate.revoked" => "AuditEventCertificateRevoked",
        "enrollment.transition" => "AuditEventEnrollmentTransition",
        "learner.launch_link_created" => "AuditEventLearnerLaunchLinkCreated",
        "learner.updated" => "AuditEventLearnerUpdated",
        "member.removed" => "AuditEventMemberRemoved",
        "member.role_changed" => "AuditEventMemberRoleChanged",
        "member.transferred" => "AuditEventMemberTransferred",
        "organization.closed" => "AuditEventOrganizationClosed",
        "organization.reopened" => "AuditEventOrganizationReopened",
        "organization.updated" => "AuditEventOrganizationUpdated",
        "seat.granted" => "AuditEventSeatGranted",
      },
      property: "type",
      fallback: "AuditEvent::Unknown",
    )
  end
end
