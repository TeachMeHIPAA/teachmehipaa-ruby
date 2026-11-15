# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A WebhookSubscriptionCreated object.
  class WebhookSubscriptionCreated < Model
    # Unique identifier for the subscription.
    field :subscription_id, "subscriptionId"
    # The HTTPS URL events are delivered to.
    field :endpoint_url, "endpointUrl"
    # The event types delivered.
    #
    # See EventType for known values; the API may send newer ones.
    field :event_types, "eventTypes"
    # Whether deliveries are on.
    field :enabled, "enabled"
    field :description, "description"
    field :seats_low_threshold, "seatsLowThreshold"
    # Identifies the signing secret.
    field :secret_key_id, "secretKeyId"
    field :created_at, "createdAt", type: :time
    field :rev, "rev"
    # The signing secret. Returned only once: store it now.
    field :secret, "secret"
  end
end
