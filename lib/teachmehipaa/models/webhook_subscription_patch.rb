# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A WebhookSubscriptionPatch object.
  #
  # Sent as a JSON merge patch: leave a field out to keep it; nil clears a nullable field.
  class WebhookSubscriptionPatch < Model
    # The HTTPS URL to deliver events to.
    field :endpoint_url, "endpointUrl"
    # The event types to deliver.
    #
    # See EventType for known values; the API may send newer ones.
    field :event_types, "eventTypes"
    # Turn deliveries on or off.
    field :enabled, "enabled"
    # A description for your own reference.
    field :description, "description"
    # Send `seats.low` when available seats drop to this number.
    field :seats_low_threshold, "seatsLowThreshold"
  end
end
