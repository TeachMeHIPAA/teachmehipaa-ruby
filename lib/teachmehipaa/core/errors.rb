# frozen_string_literal: true

module TeachMeHipaa
  # Base class for every error the library raises.
  #
  # Fields mirror the API's RFC 9457 problem body. +code+ is an open string:
  # the API adds new codes over time, so branch on known values and treat the
  # rest generically.
  class Error < StandardError
    attr_reader :status, :code, :title, :detail, :request_id, :headers, :body

    def initialize(message, status: nil, code: nil, title: nil, detail: nil, request_id: nil,
                   headers: {}, body: nil)
      @status = status
      @code = code
      @title = title
      @detail = detail
      @request_id = request_id
      @headers = headers
      @body = body
      super(request_id ? "#{message} (request id: #{request_id})" : message)
    end

    # Builds the error for a non-2xx response.
    def self.from_response(response)
      body = Core::Json.parse_body(response)
      fields = body.is_a?(Hash) ? body : {}
      # The token endpoint answers with an OAuth body ({error,
      # error_description}) rather than a problem.
      code = string(fields["code"]) || string(fields["error"])
      title = string(fields["title"])
      detail = string(fields["detail"]) || string(fields["error_description"])
      new(detail || title || code || "HTTP #{response.status}",
          status: response.status, code:, title:, detail:,
          request_id: response.headers["x-request-id"], headers: response.headers, body:)
    end

    def self.string(value)
      value if value.is_a?(String)
    end
    private_class_method :string
  end
end
