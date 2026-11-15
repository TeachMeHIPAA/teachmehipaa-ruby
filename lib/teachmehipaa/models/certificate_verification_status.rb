# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # `valid`, `expired` or `revoked`.
  #
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module CertificateVerificationStatus
    VALID = "valid"
    EXPIRED = "expired"
    REVOKED = "revoked"
  end
end
