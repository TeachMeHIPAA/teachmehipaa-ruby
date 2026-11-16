# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "enrollments_batch_request_select"

module TeachMeHipaa
  # An EnrollmentsBatchRequest object.
  class EnrollmentsBatchRequest < Model
    # What to do to each enrollment: `remind`, `resendInvite`, `cancel`, `recertify`, `archive` or
    # `unarchive`.
    #
    # See EnrollmentsBatchRequestOperation for known values; the API may send newer ones.
    #
    # @return [String]
    field :operation, "operation"
    # The enrollments to act on: a list of `enrollmentIds` (up to 500), or a `filter`.
    #
    # @return [EnrollmentsBatchRequestSelect]
    field :select, "select", type: EnrollmentsBatchRequestSelect
  end
end
