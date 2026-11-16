# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The generated methods under +client.events+. The client exposes the hand-written subclass
    # Events in lib/teachmehipaa/extensions/events.rb.
    class EventsBase < Core::Resource
      # List all events
      #
      # Returns a list of the organization's events from the last 30 days, oldest first. Pass the
      # last `eventId` you processed as `after` to resume where you stopped, and `type` to list one
      # event type.
      #
      # Needs the +webhooks:manage+ or +audit:read+ Scope.
      #
      # @param limit [Integer, nil] How many objects to return, between 1 and 100. Defaults to 20.
      # @param after [String, nil] Return events after this event id (exclusive). The previous
      #   page's `nextCursor`.
      # @param type [String, Symbol, nil] Filter to one event type.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Page<Event>]
      def list(limit: nil, after: nil, type: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/events",
          query: { limit:, after:, type: },
          retry_safe: true,
          response: :page,
          model: Event,
          pagination: { style: :after, cursor_param: "after" },
          request_options:,
        )
      end
    end
  end
end
