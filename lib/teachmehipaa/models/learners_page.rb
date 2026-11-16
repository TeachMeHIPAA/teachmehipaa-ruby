# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "learner"

module TeachMeHipaa
  # A LearnersPage object.
  class LearnersPage < Model
    # @return [Array<Learner>]
    field :items, "items", type: [Learner]
    # @return [String, nil]
    field :next_cursor, "nextCursor"
  end
end
