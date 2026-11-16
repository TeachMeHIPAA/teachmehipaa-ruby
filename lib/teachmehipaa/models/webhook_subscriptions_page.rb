# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "webhook_subscription"

module TeachMeHipaa
  # A WebhookSubscriptionsPage object.
  class WebhookSubscriptionsPage < Model
    # @return [Array<WebhookSubscription>]
    field :items, "items", type: [WebhookSubscription]
    # @return [String, nil]
    field :next_cursor, "nextCursor"
  end
end
