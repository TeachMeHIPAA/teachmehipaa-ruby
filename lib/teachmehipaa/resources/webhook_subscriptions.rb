# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.webhook_subscriptions+.
    class WebhookSubscriptions < Core::Resource
      # Create a webhook subscription
      #
      # Subscribes an HTTPS endpoint to event types and creates its signing secret. Requires the
      # `webhooks:manage` or `org:admin` scope.
      def create(endpoint_url:, event_types:, description: nil, seats_low_threshold: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/webhook-subscriptions",
          body: WebhookSubscriptionCreate.to_wire({ endpoint_url:, event_types:, description:,
                                                    seats_low_threshold: }.compact),
          retry_safe: true,
          idempotency_key: :required,
          model: WebhookSubscriptionCreated,
          request_options:,
        )
      end

      # Delete a webhook subscription
      #
      # Deletes a webhook subscription and its signing secret. Requires the `webhooks:manage` or
      # `org:admin` scope.
      def delete(subscription_id, request_options: {})
        request(
          method: "DELETE",
          path: "/organizations/{orgId}/webhook-subscriptions/{subscriptionId}",
          path_params: { subscriptionId: subscription_id },
          response: :empty,
          request_options:,
        )
      end

      # List all webhook subscriptions
      #
      # Returns a list of the organization's webhook subscriptions. Signing secrets are never
      # returned. Requires the `webhooks:manage` or `org:admin` scope.
      def list(limit: nil, cursor: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/webhook-subscriptions",
          query: { limit:, cursor: },
          retry_safe: true,
          response: :page,
          model: WebhookSubscription,
          pagination: { style: :cursor, cursor_param: "cursor" },
          request_options:,
        )
      end

      # Retry failed deliveries
      #
      # Delivers the subscription's failed events again. Requires the `webhooks:manage` or
      # `org:admin` scope.
      def redrive(subscription_id, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/webhook-subscriptions/{subscriptionId}:redrive",
          path_params: { subscriptionId: subscription_id },
          retry_safe: true,
          idempotency_key: :required,
          response: :operation,
          model: WebhookDeliveryOperation,
          request_options:,
        )
      end

      # Retrieve a webhook subscription
      #
      # Retrieves a webhook subscription. Requires the `webhooks:manage` or `org:admin` scope.
      #
      # Given +if_none_match:+ (an ETag, or the copy you hold), returns NotModified when your copy
      # is current.
      def retrieve(subscription_id, if_none_match: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/webhook-subscriptions/{subscriptionId}",
          path_params: { subscriptionId: subscription_id },
          if_none_match:,
          retry_safe: true,
          model: WebhookSubscription,
          request_options:,
        )
      end

      # Send a test event
      #
      # Sends a signed test delivery to the subscription's endpoint, so you can check your verifier.
      # Requires the `webhooks:manage` or `org:admin` scope.
      def test(subscription_id, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/webhook-subscriptions/{subscriptionId}:test",
          path_params: { subscriptionId: subscription_id },
          retry_safe: true,
          idempotency_key: :required,
          response: :operation,
          model: WebhookDeliveryOperation,
          request_options:,
        )
      end

      # Update a webhook subscription
      #
      # Updates a webhook subscription; parameters you don't send are left unchanged. Send its
      # current `ETag` in `If-Match`. The signing secret doesn't change. Requires the
      # `webhooks:manage` or `org:admin` scope.
      #
      # Parameters you leave out are unchanged; pass nil to clear one.
      def update(subscription_id, if_match:, endpoint_url: OMIT, event_types: OMIT, enabled: OMIT, description: OMIT,
                 seats_low_threshold: OMIT, request_options: {})
        request(
          method: "PATCH",
          path: "/organizations/{orgId}/webhook-subscriptions/{subscriptionId}",
          path_params: { subscriptionId: subscription_id },
          if_match:,
          body: WebhookSubscriptionPatch.to_wire({ endpoint_url:, event_types:, enabled:, description:,
                                                   seats_low_threshold: }),
          content_type: "application/merge-patch+json",
          model: WebhookSubscription,
          request_options:,
        )
      end
    end
  end
end
