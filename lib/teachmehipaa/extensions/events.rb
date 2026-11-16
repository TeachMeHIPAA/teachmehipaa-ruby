# frozen_string_literal: true

module TeachMeHipaa
  # A position in the Event log, iterated with #each (and every Enumerable
  # method). Returned by +client.events.tail+.
  #
  # #last_event_id is the id of the last Event handed out, or the +after:+
  # the tail started from. Save it to resume from the same place after a
  # restart. Iterating the same tail again carries on from it. A tail is for
  # one thread at a time.
  class EventTail
    include Enumerable

    attr_reader :last_event_id

    # @api private
    def initialize(events_after:, after:, follow:, interval:, stop:, sleep:)
      @events_after = events_after
      @last_event_id = after
      @follow = follow
      @interval = interval
      @stop = stop
      @sleep = sleep
    end

    # Yields each Event after #last_event_id, oldest first. Returns once
    # caught up, or with +follow: true+ waits the interval and polls again
    # until the block breaks or +stop+ says to. Without a block, returns an
    # Enumerator.
    def each
      return enum_for(:each) unless block_given?

      until stopped?
        # The log's next_cursor is nil at the current end, so each poll
        # starts from the last Event handed out, not from a cursor.
        @events_after.call(@last_event_id).auto_paging_each do |event|
          return self if stopped?

          @last_event_id = event["eventId"]
          yield event
          # Checked again before the loop can fetch another page.
          return self if stopped?
        end
        return self unless @follow && !stopped?

        @sleep.call(@interval)
      end
      self
    end

    # @return [String] The tail's position.
    def inspect
      "#<#{self.class.name} last_event_id=#{last_event_id.inspect}>"
    end

    private

    def stopped?
      @stop&.call ? true : false
    end
  end

  module Resources
    # The methods under +client.events+: the generated EventsBase plus #tail.
    class Events < EventsBase
      # The default +interval:+ of #tail, in seconds.
      DEFAULT_TAIL_INTERVAL = 2.0

      # Tail the event log
      #
      # Iterates the organization's Events oldest first, after +after+ (an
      # Event id, exclusive, such as a saved EventTail#last_event_id; nil
      # starts at the oldest retained Event). The log's +next_cursor+ is nil
      # at the current end, so the tail keeps its own position in
      # EventTail#last_event_id.
      #
      # Once caught up the iteration returns, or with +follow: true+ waits
      # +interval+ seconds and polls again until the block breaks or +stop+
      # says to. +stop+ is any object with +call+ (a lambda, say) that returns
      # true to end the tail; it is checked before each Event and each poll,
      # and a wait already under way finishes first. +type+ and +limit+ (per
      # request) and +request_options+ apply to every request.
      #
      #   tail = client.events.tail(after: saved_id, follow: true, stop: -> { shutting_down })
      #   tail.each { |event| handle(event) }
      #   save(tail.last_event_id)
      def tail(after: nil, type: nil, limit: nil, follow: false, interval: DEFAULT_TAIL_INTERVAL, stop: nil,
               request_options: {})
        events_after = ->(position) { list(after: position, type:, limit:, request_options:) }
        EventTail.new(events_after:, after:, follow:, interval: Float(interval), stop:, sleep: config.sleep)
      end
    end
  end
end
