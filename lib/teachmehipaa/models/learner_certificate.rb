# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # The learner's current certificate, with its verification and PDF links.
  class LearnerCertificate < Model
    field :certificate_id, "certificateId"
    field :issued_at, "issuedAt", type: :time
    field :expires_at, "expiresAt", type: :time
    field :verify_url, "verifyUrl"
    field :pdf_url, "pdfUrl"
  end
end
