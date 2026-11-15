# frozen_string_literal: true

module TeachMeHipaa
  # One invalid field from a problem's +errors+ list. +path+ is the
  # dot-joined field path, or a header name such as "Idempotency-Key".
  FieldError = Data.define(:path, :message)

  # Base class for every error the library raises (grilling Q20).
  #
  # Fields mirror the API's RFC 9457 problem body. +code+ is an open string:
  # the API adds new codes over time, so branch on known values and treat the
  # rest generically. +body+ is the raw response text. Errors raised without
  # a response leave the response fields empty.
  class Error < StandardError
    attr_reader :status, :code, :title, :detail, :errors, :request_id, :headers, :body

    def initialize(message, status: nil, code: nil, title: nil, detail: nil, errors: [], request_id: nil,
                   headers: {}, body: nil)
      @status = status
      @code = code
      @title = title
      @detail = detail
      @errors = errors
      @request_id = request_id
      @headers = headers
      @body = body
      super(request_id ? "#{message} (request id: #{request_id})" : message)
    end

    # Builds the error for a non-2xx API response: the class by status, then
    # by +code+.
    def self.from_response(response)
      problem = Core::Json.object_body(response)
      return APIError.unexpected(response) if problem.nil?

      code = string(problem["code"])
      title = string(problem["title"])
      detail = string(problem["detail"])
      error_class_for(response.status, code).new(
        detail || title || code || "HTTP #{response.status}",
        code:, title:, detail:, errors: field_errors(problem["errors"]), **response_fields(response),
      )
    end

    # Builds the error for a token endpoint response, which carries the OAuth
    # shape ({error, error_description}) rather than a problem.
    def self.from_oauth_response(response)
      body = Core::Json.object_body(response)
      oauth_code = string(body&.fetch("error", nil))
      return from_response(response) if oauth_code.nil?

      detail = string(body["error_description"])
      OAuthError.new(detail || oauth_code, code: oauth_code, detail:, **response_fields(response))
    end

    STATUS_ERRORS = {
      400 => :InvalidRequestError,
      401 => :AuthenticationError,
      403 => :PermissionDeniedError,
      404 => :NotFoundError,
      405 => :InvalidRequestError,
      406 => :InvalidRequestError,
      409 => :ConflictError,
      412 => :PreconditionFailedError,
      415 => :InvalidRequestError,
      422 => :InvalidRequestError,
      428 => :PreconditionFailedError,
      429 => :RateLimitError,
    }.freeze
    private_constant :STATUS_ERRORS

    def self.error_class_for(status, code)
      error_class = TeachMeHipaa.const_get(STATUS_ERRORS.fetch(status, :APIError))
      return IdempotencyError if error_class == InvalidRequestError && code == "idempotency_key_reuse"

      error_class
    end

    def self.response_fields(response)
      {
        status: response.status,
        request_id: response.headers["x-request-id"],
        headers: response.headers,
        body: response.body,
      }
    end

    def self.field_errors(value)
      return [] unless value.is_a?(Array)

      value.grep(Hash).map { |item| FieldError.new(path: item["path"].to_s, message: item["message"].to_s) }
    end

    def self.string(value)
      value if value.is_a?(String)
    end
    private_class_method :error_class_for, :response_fields, :field_errors, :string
  end

  # 401: the Access token is missing, expired or revoked.
  class AuthenticationError < Error; end

  # 403: the token lacks a Scope, or the Organization refuses the action.
  class PermissionDeniedError < Error; end

  # 404: no such object in the bound Organization.
  class NotFoundError < Error; end

  # 409: the object's state forbids the action, or an identical request is
  # still in flight (+code+ "conflict").
  class ConflictError < Error; end

  # 412 for a stale If-Match, 428 for a missing one.
  class PreconditionFailedError < Error; end

  # 400, 405, 406, 415 or 422: the request itself is wrong.
  class InvalidRequestError < Error; end

  # 422 "idempotency_key_reuse": the key was already used with another body.
  class IdempotencyError < InvalidRequestError; end

  # 429: too many requests.
  class RateLimitError < Error
    # Seconds the API asked the caller to wait, from Retry-After, or nil.
    def retry_after
      Core::Json.retry_after(headers)
    end
  end

  # 5xx, an unlisted status, or a response the API should never send, such
  # as an HTML page where JSON was expected.
  class APIError < Error
    def self.unexpected(response, expected: "JSON")
      content_type = response.headers["content-type"] || "no content type"
      new("The API answered HTTP #{response.status} with #{content_type} instead of #{expected}. " \
          "Check that base_url points at the TeachMeHIPAA API.", **response_fields(response))
    end
  end

  # The token endpoint refused a grant. +code+ is the OAuth +error+ and
  # +detail+ its +error_description+.
  class OAuthError < Error; end

  # No response arrived: DNS, connect, TLS or a dropped connection. +cause+
  # is the transport's own exception.
  class APIConnectionError < Error; end

  # No response arrived within the timeout.
  class APITimeoutError < APIConnectionError; end

  # An Operation finished with an error: the problem's fields are on this
  # error, the request id is the response that reported it, and +operation+
  # is the failed Operation.
  class OperationFailedError < Error
    attr_reader :operation

    def initialize(message, operation:, **fields)
      @operation = operation
      super(message, **fields)
    end

    # The error a done Operation with an +error+ finished with.
    def self.from_operation(operation)
      problem = operation.error
      new(problem.detail || problem.title || problem.code || "Operation #{operation.name} failed",
          operation:, status: problem.status, code: problem.code, title: problem.title, detail: problem.detail,
          errors: Array(problem.errors).map { |item| FieldError.new(path: item.path.to_s, message: item.message.to_s) },
          **response_fields(operation.last_response))
    end

    # An Operation built by hand has no response.
    def self.response_fields(last_response)
      return {} if last_response.nil?

      { request_id: last_response.request_id, headers: last_response.headers }
    end
    private_class_method :response_fields
  end

  # Operation#wait ran out of time. +operation+ is the last state seen; it
  # may still finish, so it can be waited on again.
  class OperationTimeoutError < Error
    attr_reader :operation

    def initialize(message, operation:)
      @operation = operation
      last_response = operation.last_response
      super(message, request_id: last_response&.request_id, headers: last_response&.headers || {})
    end
  end

  # A webhook Delivery failed verification. +code+ says why:
  # "missing_header", "invalid_timestamp", "timestamp_outside_tolerance",
  # "body_hash_mismatch" or "signature_mismatch". Carries neither the body
  # nor the headers, which may hold PHI (ADR-0007).
  class WebhookSignatureError < Error
    def initialize(code, message)
      super(message, code:)
    end
  end
end
