# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Seats by internal state. Prefer `purchased`, `assigned` and `available`.
  class SeatsInventoryByState < Model
    # @return [Integer]
    field :unused, "UNUSED"
    # @return [Integer]
    field :assigned, "ASSIGNED"
    # @return [Integer]
    field :accepted, "ACCEPTED"
    # @return [Integer]
    field :revoked, "REVOKED"
    # @return [Integer]
    field :free, "FREE"
    # @return [Integer]
    field :refunded, "REFUNDED"
  end
end
