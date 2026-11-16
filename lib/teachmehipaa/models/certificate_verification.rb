# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A CertificateVerification object.
  class CertificateVerification < Model
    # `valid`, `expired` or `revoked`.
    #
    # See CertificateVerificationStatus for known values; the API may send newer ones.
    #
    # @return [String]
    field :status, "status"
    # The name printed on the certificate.
    #
    # @return [String]
    field :learner_name, "learnerName"
    # The course.
    #
    # @return [String]
    field :course_title, "courseTitle"
    # When it was issued (ISO 8601).
    #
    # @return [Time]
    field :issued_at, "issuedAt", type: :time
    # When it expires.
    #
    # @return [Time]
    field :expires_at, "expiresAt", type: :time
    # Who issued it.
    #
    # See CertificateVerificationIssuer for known values; the API may send newer ones.
    #
    # @return [String]
    field :issuer, "issuer"
  end
end
