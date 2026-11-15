# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # The If-Match and If-None-Match headers of a conditional request.
    #
    # @api private
    module Conditional
      module_function

      # Each ETag is a String, or an object the client returned (its last
      # response's ETag); nil leaves the header out.
      def headers(if_match:, if_none_match:)
        { "if-match" => etag(if_match, :if_match), "if-none-match" => etag(if_none_match, :if_none_match) }.compact
      end

      # Refused before anything is sent: without its ETag the request would
      # go out unconditional, or be answered 428.
      def etag(value, name)
        return value if value.nil? || value.is_a?(String)

        etag = value.respond_to?(:last_response) ? value.last_response&.etag : nil
        return etag unless etag.nil?

        raise ArgumentError, "#{name}: #{value.class} was not read from a response with an ETag; " \
                             "pass the ETag String instead"
      end
    end
  end
end
