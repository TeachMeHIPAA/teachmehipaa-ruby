# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Whether the holder could be resolved: `resolved`, `none` or `lookup_failed`.
  #
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module CertificateHolderStatus
    RESOLVED = "resolved"
    NONE = "none"
    LOOKUP_FAILED = "lookup_failed"
  end
end
