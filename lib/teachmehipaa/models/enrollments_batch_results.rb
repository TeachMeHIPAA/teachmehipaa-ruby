# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "enrollments_batch_results_results_item"

module TeachMeHipaa
  # An EnrollmentsBatchResults object.
  class EnrollmentsBatchResults < Model
    # The operation that was run.
    #
    # See EnrollmentsBatchResultsOperation for known values; the API may send newer ones.
    field :operation, "operation"
    # One result per enrollment: `succeeded`, `skipped` or `failed` with a problem.
    field :results, "results", type: [EnrollmentsBatchResultsResultsItem]
  end
end
