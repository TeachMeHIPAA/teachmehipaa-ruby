# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A WebhookSubscription object.
  class WebhookSubscription < Model
    # Unique identifier for the subscription.
    #
    # @return [String]
    field :subscription_id, "subscriptionId"
    # The HTTPS URL events are delivered to.
    #
    # @return [String]
    field :endpoint_url, "endpointUrl"
    # The event types delivered.
    #
    # See EventType for known values; the API may send newer ones.
    #
    # @return [Array<String>]
    field :event_types, "eventTypes"
    # Whether deliveries are on.
    #
    # @return [Boolean]
    field :enabled, "enabled"
    # Your description of the subscription.
    #
    # @return [String, nil]
    field :description, "description"
    # Send `seats.low` when available seats drop to this number. Defaults to 5.
    #
    # @return [Integer]
    field :seats_low_threshold, "seatsLowThreshold"
    # Identifies the signing secret. Sent as `x-tmh-key-id`.
    #
    # @return [String]
    field :secret_key_id, "secretKeyId"
    # When it was created (ISO 8601).
    #
    # @return [Time]
    field :created_at, "createdAt", type: :time
    # The resource's revision. Its strong `ETag` is derived from it.
    #
    # @return [Integer]
    field :rev, "rev"
  end
end
