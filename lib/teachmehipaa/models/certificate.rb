# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A Certificate object.
  class Certificate < Model
    # Unique identifier for the certificate.
    field :certificate_id, "certificateId"
    # The holder's member id.
    field :subject_id, "subjectId"
    # Whether the holder could be resolved: `resolved`, `none` or `lookup_failed`.
    #
    # See CertificateHolderStatus for known values; the API may send newer ones.
    field :holder_status, "holderStatus"
    # The course the certificate is for.
    field :course_id, "courseId"
    # The course version the holder passed.
    field :course_version, "courseVersion"
    # When it was issued (ISO 8601).
    field :issued_at, "issuedAt"
    # When it expires.
    field :expires_at, "expiresAt"
    # `VALID`, `EXPIRED` or `REVOKED`.
    #
    # See CertificateStatus for known values; the API may send newer ones.
    field :status, "status"
    # When it was revoked, if it was.
    field :revoked_at, "revokedAt"
  end
end
