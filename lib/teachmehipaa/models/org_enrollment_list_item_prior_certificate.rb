# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An OrgEnrollmentListItemPriorCertificate object.
  class OrgEnrollmentListItemPriorCertificate < Model
    # @return [String]
    field :certificate_id, "certificateId"
    # @return [String, nil]
    field :issued_at, "issuedAt"
    # @return [String, nil]
    field :expires_at, "expiresAt"
    # See OrgEnrollmentListItemPriorCertificateStatus for known values; the API may send newer ones.
    #
    # @return [String]
    field :status, "status"
  end
end
