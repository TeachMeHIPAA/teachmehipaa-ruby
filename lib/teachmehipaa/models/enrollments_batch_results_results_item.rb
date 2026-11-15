# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "problem"

module TeachMeHipaa
  # An EnrollmentsBatchResultsResultsItem object.
  class EnrollmentsBatchResultsResultsItem < Model
    field :enrollment_id, "enrollmentId"
    # See EnrollmentsBatchResultsResultsItemOutcome for known values; the API may send newer ones.
    field :outcome, "outcome"
    field :problem, "problem", type: Problem
  end
end
