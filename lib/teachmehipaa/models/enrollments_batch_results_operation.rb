# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # The operation that was run.
  #
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module EnrollmentsBatchResultsOperation
    REMIND = "remind"
    RESEND_INVITE = "resendInvite"
    CANCEL = "cancel"
    RECERTIFY = "recertify"
    ARCHIVE = "archive"
    UNARCHIVE = "unarchive"
  end
end
