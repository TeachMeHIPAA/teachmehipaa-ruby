# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A CertificateVerification object.
  class CertificateVerification < Model
    # `valid`, `expired` or `revoked`.
    #
    # See CertificateVerificationStatus for known values; the API may send newer ones.
    field :status, "status"
    # The name printed on the certificate.
    field :learner_name, "learnerName"
    # The course.
    field :course_title, "courseTitle"
    # When it was issued (ISO 8601).
    field :issued_at, "issuedAt", type: :time
    # When it expires.
    field :expires_at, "expiresAt", type: :time
    # Who issued it.
    #
    # See CertificateVerificationIssuer for known values; the API may send newer ones.
    field :issuer, "issuer"
  end
end
