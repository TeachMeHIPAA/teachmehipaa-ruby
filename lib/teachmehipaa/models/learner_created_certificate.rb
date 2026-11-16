# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnerCreatedCertificate object.
  class LearnerCreatedCertificate < Model
    # @return [String]
    field :certificate_id, "certificateId"
    # @return [Time]
    field :issued_at, "issuedAt", type: :time
    # @return [Time]
    field :expires_at, "expiresAt", type: :time
    # @return [String, nil]
    field :verify_url, "verifyUrl"
    # @return [String]
    field :pdf_url, "pdfUrl"
  end
end
