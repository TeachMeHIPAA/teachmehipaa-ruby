# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # Reads response bodies. Checks the media type before parsing, because
    # the API answers unknown paths with a 200 HTML page.
    module Json
      module_function

      def success_body(response)
        raise Error.from_response(response) unless (200..299).cover?(response.status)

        body = parse_body(response)
        return body unless body.is_a?(String)

        raise Error.new(
          "Expected a JSON response, got #{response.headers["content-type"].inspect}",
          status: response.status, request_id: response.headers["x-request-id"],
          headers: response.headers, body:
        )
      end

      # The parsed JSON body, or the raw text when the body isn't JSON.
      def parse_body(response)
        return response.body unless json?(response.headers["content-type"])

        JSON.parse(response.body)
      rescue JSON::ParserError
        response.body
      end

      def json?(content_type)
        media_type = content_type.to_s.split(";").first.to_s.strip.downcase
        media_type == "application/json" || media_type.end_with?("+json")
      end
    end
  end
end
