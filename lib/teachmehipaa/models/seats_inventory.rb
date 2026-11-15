# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "seats_inventory_by_state"

module TeachMeHipaa
  # A SeatsInventory object.
  class SeatsInventory < Model
    # All seats on record.
    field :total, "total"
    # Seats in use.
    field :used, "used"
    # Seats a new invite can use now.
    field :available, "available"
    # Seats the organization holds and hasn't been refunded for, including a trial seat.
    field :purchased, "purchased"
    # Seats held by an invited or enrolled learner.
    field :assigned, "assigned"
    # Seats by internal state. Prefer `purchased`, `assigned` and `available`.
    field :by_state, "byState", type: SeatsInventoryByState
  end
end
