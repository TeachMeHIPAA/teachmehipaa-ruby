# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A WebhookSubscriptionCreated object.
  class WebhookSubscriptionCreated < Model
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
    # @return [String, nil]
    field :description, "description"
    # @return [Integer]
    field :seats_low_threshold, "seatsLowThreshold"
    # Identifies the signing secret.
    #
    # @return [String]
    field :secret_key_id, "secretKeyId"
    # @return [Time]
    field :created_at, "createdAt", type: :time
    # @return [Integer]
    field :rev, "rev"
    # The signing secret. Returned only once: store it now.
    #
    # @return [String]
    field :secret, "secret"
  end
end
