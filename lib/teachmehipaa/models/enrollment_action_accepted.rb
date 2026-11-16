# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An EnrollmentActionAccepted object.
  class EnrollmentActionAccepted < Model
    # The enrollment the request is for.
    #
    # @return [String]
    field :enrollment_id, "enrollmentId"
    # The action that was accepted: `remind` or `resendInvite`.
    #
    # See EnrollmentActionAcceptedAction for known values; the API may send newer ones.
    #
    # @return [String]
    field :action, "action"
  end
end
