# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "problem"

module TeachMeHipaa
  # An Operation object.
  class Operation < Model
    # Unique identifier for the operation.
    field :name, "name"
    # Whether the operation has finished.
    field :done, "done"
    # Progress information, if any.
    field :metadata, "metadata"
    # The result, once `done` is `true`.
    field :response, "response"
    # The problem, if the operation failed.
    field :error, "error", type: Problem
  end
end
