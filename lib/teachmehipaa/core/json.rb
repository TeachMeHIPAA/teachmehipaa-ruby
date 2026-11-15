# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # Reads response bodies. Checks the media type before parsing, because
    # the API answers unknown paths with a 200 HTML page.
    #
    # @api private
    module Json
      module_function

      def success_body(response)
        raise Error.from_response(response) unless (200..299).cover?(response.status)
        raise APIError.unexpected(response) unless json?(response.headers["content-type"])

        JSON.parse(response.body)
      rescue JSON::ParserError
        raise APIError.unexpected(response)
      end

      # The parsed body when it is a JSON object, else nil.
      def object_body(response)
        return nil unless json?(response.headers["content-type"])

        body = JSON.parse(response.body)
        body.is_a?(Hash) ? body : nil
      rescue JSON::ParserError
        nil
      end

      def json?(content_type)
        media_type = content_type.to_s.split(";").first.to_s.strip.downcase
        media_type == "application/json" || media_type.end_with?("+json")
      end

      # The API only sends delta-seconds. An HTTP-date would need a wall
      # clock, which the library deliberately doesn't read, so it is ignored
      # and the caller falls back to backoff.
      def retry_after(headers)
        seconds = Float(headers["retry-after"], exception: false)
        seconds if seconds&.finite? && !seconds.negative?
      end
    end
  end
end
