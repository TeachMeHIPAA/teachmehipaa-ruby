# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Applies to every item. `require_available` fails an item when no seat is free.
  #
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module LearnerBatchUpsertRequestSeatPolicy
    REQUIRE_AVAILABLE = "require_available"
  end
end
