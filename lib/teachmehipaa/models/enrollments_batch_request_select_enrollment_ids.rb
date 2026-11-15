# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "enrollments_batch_request_select"

module TeachMeHipaa
  # An EnrollmentsBatchRequestSelectEnrollmentIds object.
  class EnrollmentsBatchRequestSelectEnrollmentIds < Model
    include EnrollmentsBatchRequestSelect

    field :enrollment_ids, "enrollmentIds"
  end
end
