# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # Where a list's next page starts, by the IR's pagination style.
    #
    # @api private
    module Pagination
      module_function

      # The value of the list's cursor parameter that asks for the page after
      # +page+. A +:cursor+ list passes the opaque +next_cursor+ back. The
      # Event log (+:after+) keys on Event ids: +next_cursor+ is the last id
      # while more rows exist, so the last Event is the authoritative position,
      # and only an empty page falls back to +next_cursor+.
      def position(style, page)
        return page.next_cursor if style == :cursor || page.items.empty?

        event_id = page.items.last["eventId"]
        event_id.is_a?(String) ? event_id : page.next_cursor
      end
    end
  end
end
