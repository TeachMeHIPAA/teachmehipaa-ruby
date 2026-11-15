# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Seats by internal state. Prefer `purchased`, `assigned` and `available`.
  class SeatsInventoryByState < Model
    field :unused, "UNUSED"
    field :assigned, "ASSIGNED"
    field :accepted, "ACCEPTED"
    field :revoked, "REVOKED"
    field :free, "FREE"
    field :refunded, "REFUNDED"
  end
end
