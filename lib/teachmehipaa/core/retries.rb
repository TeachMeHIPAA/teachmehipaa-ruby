# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # Sending with retries (grilling Q18). The decisions are pure; only
    # Retries.call sends and waits.
    #
    # @api private
    module Retries
      INITIAL_DELAY = 0.5
      MAX_DELAY = 5.0
      MAX_RETRY_AFTER = 60.0

      # Whether and how often one call may be retried. Only retry-safe calls
      # retry: replaying anything else after a lost response could apply it
      # twice.
      Policy = Data.define(:retry_safe, :max_retries) do
        # The policy for an API call: only the IR's +retry_safe+ allows
        # retries, since the server ignores an Idempotency-Key elsewhere, and
        # never for a PATCH or DELETE, whatever the IR says.
        def self.for(method, retry_safe:, max_retries:)
          new(retry_safe: retry_safe && !NEVER_RETRIED.include?(method), max_retries:)
        end
      end
      # Never replayed once a response may have been received (grilling
      # Q18): a lost success would apply twice or surface as a confusing
      # 412 or 404.
      NEVER_RETRIED = %w[PATCH DELETE].freeze

      module_function

      # Sends one call through +connection+, retrying transient failures as
      # +policy+ allows, and returns the 2xx response or raises the last
      # error. The block builds the request's keyword arguments for
      # Connection#request afresh for each attempt; anything it raises (a
      # failed token mint, say) ends the call. +map_error+ turns a non-2xx
      # response into an Error. +replay+, when given, is called with the
      # refused request's arguments on the call's first 401 "unauthorized",
      # and the request is sent again if it answers true. With +not_modified+, a 304 (the
      # answer to If-None-Match) is returned like a success.
      def call(connection, policy, map_error:, replay: nil, not_modified: false)
        retries = 0
        replayed = false
        loop do
          request = yield
          response, error = attempt(connection, request, map_error, not_modified)
          return response if error.nil?

          # A token revoked mid-flight earns one fresh token and a replay,
          # outside the retry budget: it says nothing about the API's health.
          if replay && !replayed && unauthorized?(error)
            replayed = true
            next if replay.call(request)
          end
          wait = next_delay(policy, retries, error)
          raise error if wait.nil?

          connection.config.sleep.call(wait)
          retries += 1
        end
      end

      def attempt(connection, request, map_error, not_modified)
        response = connection.request(**request)
        return [response, nil] if Responses.success?(response.status) || (not_modified && response.status == 304)

        [nil, map_error.call(response)]
      rescue APIConnectionError => e
        [nil, e]
      end

      def next_delay(policy, retries, error)
        return nil unless policy.retry_safe && retries < policy.max_retries && transient?(error)

        delay(retries, error)
      end

      # Other 409 codes are business conflicts a replay can't fix;
      # "conflict" means the same Idempotency-Key is still in flight.
      def transient?(error)
        return true if error.is_a?(APIConnectionError)

        status = error.status
        !status.nil? && (status >= 500 || status == 429 || (status == 409 && error.code == "conflict"))
      end

      def delay(retries, error)
        retry_after = Json.retry_after(error.headers)
        return [retry_after, MAX_RETRY_AFTER].min unless retry_after.nil?

        backoff(INITIAL_DELAY, retries, MAX_DELAY)
      end

      # Seconds to wait before retry (or poll) number +attempt+, from 0:
      # +base+ doubled each time up to +cap+, of which jitter picks 50-100%,
      # and never less than +base+.
      def backoff(base, attempt, cap)
        nominal = [base * (2**attempt), cap].min
        # Jitter spreads out clients that failed together; it is not security.
        [nominal * (0.5 + (Random.rand / 2)), base].max
      end

      def unauthorized?(error)
        error.is_a?(AuthenticationError) && error.code == "unauthorized"
      end

      private_class_method :attempt, :next_delay, :transient?, :delay, :unauthorized?
    end
  end
end
