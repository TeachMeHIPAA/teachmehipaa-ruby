# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # The body of a :test delivery. It is not an event envelope; its x-tmh-event-id is a UUID.
  class TestDelivery < Model
    # The subscription that was tested.
    field :subscription_id, "subscriptionId"
    # Always true.
    field :test, "test"
  end
end
