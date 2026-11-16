# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "problem"

module TeachMeHipaa
  # The generated fields of Operation. The library returns the hand-written subclass Operation in
  # lib/teachmehipaa/extensions/operation.rb.
  class OperationBase < Model
    # Unique identifier for the operation.
    #
    # @return [String]
    field :name, "name"
    # Whether the operation has finished.
    #
    # @return [Boolean]
    field :done, "done"
    # Progress information, if any.
    #
    # @return [Hash{String => Object}, nil]
    field :metadata, "metadata"
    # The result, once `done` is `true`.
    #
    # @return [Object]
    field :response, "response"
    # The problem, if the operation failed.
    #
    # @return [Problem, nil]
    field :error, "error", type: Problem
  end
end
