# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # `require_available` fails with `409` when no seat is free.
  #
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module LearnerCreateRequestSeatPolicy
    REQUIRE_AVAILABLE = "require_available"
  end
end
