# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "seats_inventory_by_state"

module TeachMeHipaa
  # A SeatsInventory object.
  class SeatsInventory < Model
    # All seats on record.
    #
    # @return [Integer]
    field :total, "total"
    # Seats in use.
    #
    # @return [Integer]
    field :used, "used"
    # Seats a new invite can use now.
    #
    # @return [Integer]
    field :available, "available"
    # Seats the organization holds and hasn't been refunded for, including a trial seat.
    #
    # @return [Integer, nil]
    field :purchased, "purchased"
    # Seats held by an invited or enrolled learner.
    #
    # @return [Integer, nil]
    field :assigned, "assigned"
    # Seats by internal state. Prefer `purchased`, `assigned` and `available`.
    #
    # @return [SeatsInventoryByState]
    field :by_state, "byState", type: SeatsInventoryByState
  end
end
