# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A WebhookSubscriptionCreate object.
  class WebhookSubscriptionCreate < Model
    # The HTTPS URL to deliver events to.
    field :endpoint_url, "endpointUrl"
    # The event types to deliver.
    #
    # See EventType for known values; the API may send newer ones.
    field :event_types, "eventTypes"
    # A description for your own reference.
    field :description, "description"
    # Send `seats.low` when available seats drop to this number. Defaults to 5.
    field :seats_low_threshold, "seatsLowThreshold"
  end
end
