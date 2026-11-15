# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # The status to display. Adds `EXPIRING`, `EXPIRED` and `ARCHIVED`, derived when you read it.
  #
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module EnrollmentEffectiveStatus
    INVITED = "INVITED"
    EMAIL_BOUNCED = "EMAIL_BOUNCED"
    STARTED = "STARTED"
    ASSESSMENT_IN_PROGRESS = "ASSESSMENT_IN_PROGRESS"
    CERTIFIED = "CERTIFIED"
    CANCELLED = "CANCELLED"
    EXPIRING = "EXPIRING"
    EXPIRED = "EXPIRED"
    ARCHIVED = "ARCHIVED"
  end
end
