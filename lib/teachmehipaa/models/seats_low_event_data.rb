# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A SeatsLowEventData object.
  class SeatsLowEventData < Model
    # @return [Integer]
    field :available, "available"
    # @return [Integer]
    field :threshold, "threshold"
  end
end
