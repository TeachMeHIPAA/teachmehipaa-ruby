# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "problem_errors_item"

module TeachMeHipaa
  # A Problem object.
  class Problem < Model
    # A URI identifying the problem type.
    field :type, "type"
    # A short summary of the problem.
    field :title, "title"
    # The HTTP status code.
    field :status, "status"
    # An explanation of this occurrence.
    field :detail, "detail"
    # Identifies this occurrence.
    field :instance, "instance"
    # A machine-readable error code, such as `seat_unavailable`.
    #
    # See ProblemCode for known values; the API may send newer ones.
    field :code, "code"
    # Each invalid field, with its `path` and `message`.
    field :errors, "errors", type: [ProblemErrorsItem]
  end
end
