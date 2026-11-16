# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # `email` (default) sends the invite email. `none` sends nothing and returns `joinUrl` for you to
  # deliver.
  #
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module LearnerCreateRequestDelivery
    EMAIL = "email"
    NONE = "none"
  end
end
