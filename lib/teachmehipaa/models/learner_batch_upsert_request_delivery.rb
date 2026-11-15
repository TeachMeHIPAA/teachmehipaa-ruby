# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Applies to every item. `email` (default) sends invites; `none` sends nothing.
  #
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module LearnerBatchUpsertRequestDelivery
    EMAIL = "email"
    NONE = "none"
  end
end
