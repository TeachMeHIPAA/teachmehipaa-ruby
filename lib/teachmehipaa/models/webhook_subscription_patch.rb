# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A WebhookSubscriptionPatch object.
  #
  # Sent as a JSON merge patch: leave a field out to keep it; nil clears a nullable field.
  class WebhookSubscriptionPatch < Model
    # The HTTPS URL to deliver events to.
    #
    # @return [String, nil]
    field :endpoint_url, "endpointUrl"
    # The event types to deliver.
    #
    # See EventType for known values; the API may send newer ones.
    #
    # @return [Array<String>, nil]
    field :event_types, "eventTypes"
    # Turn deliveries on or off.
    #
    # @return [Boolean, nil]
    field :enabled, "enabled"
    # A description for your own reference.
    #
    # @return [String, nil]
    field :description, "description"
    # Send `seats.low` when available seats drop to this number.
    #
    # @return [Integer, nil]
    field :seats_low_threshold, "seatsLowThreshold"
  end
end
