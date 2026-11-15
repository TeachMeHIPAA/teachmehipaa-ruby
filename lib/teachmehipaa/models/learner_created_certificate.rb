# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnerCreatedCertificate object.
  class LearnerCreatedCertificate < Model
    field :certificate_id, "certificateId"
    field :issued_at, "issuedAt", type: :time
    field :expires_at, "expiresAt", type: :time
    field :verify_url, "verifyUrl"
    field :pdf_url, "pdfUrl"
  end
end
