# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.events+.
    class Events < Core::Resource
      # List all events
      #
      # Returns a list of the organization's events from the last 30 days, oldest first. Pass the
      # last `eventId` you processed as `after` to resume where you stopped, and `type` to list one
      # event type.
      def list(limit: nil, after: nil, type: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/events",
          query: { limit:, after:, type: },
          retry_safe: true,
          response: :page,
          model: Event,
          request_options:,
        )
      end
    end
  end
end
