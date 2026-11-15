# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "enrollments_batch_request_select"
require_relative "enrollments_batch_request_select_filter_filter"

module TeachMeHipaa
  # An EnrollmentsBatchRequestSelectFilter object.
  class EnrollmentsBatchRequestSelectFilter < Model
    include EnrollmentsBatchRequestSelect

    field :filter, "filter", type: EnrollmentsBatchRequestSelectFilterFilter
  end
end
