# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An OrgEnrollmentListItemPriorCertificate object.
  class OrgEnrollmentListItemPriorCertificate < Model
    field :certificate_id, "certificateId"
    field :issued_at, "issuedAt"
    field :expires_at, "expiresAt"
    # See OrgEnrollmentListItemPriorCertificateStatus for known values; the API may send newer ones.
    field :status, "status"
  end
end
