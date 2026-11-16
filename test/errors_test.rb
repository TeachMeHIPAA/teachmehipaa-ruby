# frozen_string_literal: true

require_relative "test_helper"

class ErrorsTest < Minitest::Test
  include ClientHelpers

  STATUS_ERRORS = {
    [400, "validation_failed"] => TeachMeHipaa::InvalidRequestError,
    [401, "unauthorized"] => TeachMeHipaa::AuthenticationError,
    [403, "org_not_active"] => TeachMeHipaa::PermissionDeniedError,
    [404, "not_found"] => TeachMeHipaa::NotFoundError,
    [405, "method_not_allowed"] => TeachMeHipaa::InvalidRequestError,
    [406, "not_acceptable"] => TeachMeHipaa::InvalidRequestError,
    [409, "seat_unavailable"] => TeachMeHipaa::ConflictError,
    [412, "precondition_failed"] => TeachMeHipaa::PreconditionFailedError,
    [415, "unsupported_media_type"] => TeachMeHipaa::InvalidRequestError,
    [422, "validation_failed"] => TeachMeHipaa::InvalidRequestError,
    [428, "precondition_required"] => TeachMeHipaa::PreconditionFailedError,
    [429, "rate_limited"] => TeachMeHipaa::RateLimitError,
    [500, "internal"] => TeachMeHipaa::APIError,
    [502, "refund_failed"] => TeachMeHipaa::APIError,
    [503, "temporarily_unavailable"] => TeachMeHipaa::APIError,
  }.freeze

  STATUS_ERRORS.each do |(status, code), error_class|
    define_method("test_#{status}_#{code}_raises_#{error_class.name.split("::").last}") do
      error = retrieve_failing_with(problem(status, code))

      assert_instance_of error_class, error
      assert_equal [status, code], [error.status, error.code]
    end
  end

  def test_every_error_is_a_teachmehipaa_error
    [TeachMeHipaa::APIConnectionError, TeachMeHipaa::OAuthError, TeachMeHipaa::IdempotencyError].each do |error_class|
      assert_operator error_class, :<, TeachMeHipaa::Error
    end
    assert_operator TeachMeHipaa::Error, :<, StandardError
  end

  def test_an_unlisted_status_raises_an_api_error
    error = retrieve_failing_with(problem(418, "teapot"))

    assert_instance_of TeachMeHipaa::APIError, error
    assert_equal [418, "teapot"], [error.status, error.code]
  end

  def test_idempotency_key_reuse_raises_the_idempotency_error
    error = retrieve_failing_with(problem(422, "idempotency_key_reuse"))

    assert_instance_of TeachMeHipaa::IdempotencyError, error
    assert_kind_of TeachMeHipaa::InvalidRequestError, error
  end

  def test_an_unknown_code_is_kept_as_an_open_string
    error = retrieve_failing_with(problem(409, "brand_new_conflict"))

    assert_instance_of TeachMeHipaa::ConflictError, error
    assert_equal "brand_new_conflict", error.code
  end

  def test_the_error_carries_every_problem_field
    error = retrieve_failing_with(
      problem(422, "validation_failed",
              title: "Validation failed", detail: "2 fields are invalid.",
              errors: [{ "path" => "email", "message" => "Invalid email" },
                       { "path" => "Idempotency-Key", "message" => "Required" }]),
    )

    assert_equal "Validation failed", error.title
    assert_equal "2 fields are invalid.", error.detail
    assert_equal [TeachMeHipaa::FieldError.new(path: "email", message: "Invalid email"),
                  TeachMeHipaa::FieldError.new(path: "Idempotency-Key", message: "Required")],
                 error.errors
    assert_equal ["email", "Invalid email"], [error.errors.first.path, error.errors.first.message]
    assert_equal REQUEST_ID, error.request_id
    assert_equal "application/problem+json", error.headers["content-type"]
    assert_includes error.body, '"Invalid email"'
    assert_equal "2 fields are invalid. (request id: #{REQUEST_ID})", error.message
  end

  def test_a_problem_without_field_errors_has_an_empty_list
    assert_empty retrieve_failing_with(problem(404, "not_found")).errors
  end

  def test_a_rate_limit_error_carries_retry_after
    error = retrieve_failing_with(problem(429, "rate_limited", headers: { "retry-after" => "7" }))

    assert_instance_of TeachMeHipaa::RateLimitError, error
    assert_in_delta 7.0, error.retry_after
  end

  def test_a_rate_limit_error_without_retry_after_has_none
    assert_nil retrieve_failing_with(problem(429, "rate_limited")).retry_after
  end

  def test_a_200_html_page_raises_an_api_error_not_a_parse_error
    error = retrieve_failing_with(
      FakeTransport::Reply.new(status: 200, body: "<!doctype html><html><body>Nuxt</body></html>",
                               headers: {}, content_type: "text/html; charset=utf-8"),
    )

    assert_instance_of TeachMeHipaa::APIError, error
    assert_equal 200, error.status
    assert_nil error.code
    assert_equal "<!doctype html><html><body>Nuxt</body></html>", error.body
    assert_match %r{text/html}, error.message
  end

  def test_malformed_json_raises_an_api_error
    error = retrieve_failing_with(
      FakeTransport::Reply.new(status: 200, body: "{\"learnerId\":", headers: {}, content_type: "application/json"),
    )

    assert_instance_of TeachMeHipaa::APIError, error
    assert_equal "{\"learnerId\":", error.body
  end

  def test_an_html_error_page_raises_an_api_error
    error = retrieve_failing_with(
      FakeTransport::Reply.new(status: 404, body: "<html>404</html>", headers: {}, content_type: "text/html"),
    )

    assert_instance_of TeachMeHipaa::APIError, error
    assert_equal 404, error.status
  end

  def test_the_gateway_envelope_without_a_problem_still_raises_an_api_error
    error = retrieve_failing_with(
      FakeTransport::Reply.json({ "statusCode" => 503, "statusMessage" => "Service Unavailable" }, status: 503),
    )

    assert_instance_of TeachMeHipaa::APIError, error
    assert_equal [503, nil], [error.status, error.code]
  end

  def test_a_token_endpoint_error_raises_the_oauth_error
    transport = FakeTransport.new
    transport.on("POST", "/auth/token", FakeTransport::Reply.json(
                                          { "error" => "invalid_scope", "error_description" => "Unknown scope." },
                                          status: 400, headers: { "x-request-id" => "req_token" },
                                        ))

    error = assert_raises(TeachMeHipaa::OAuthError) { build_client(transport).learners.retrieve(LEARNER_ID) }

    assert_equal [400, "invalid_scope"], [error.status, error.code]
    assert_equal "Unknown scope.", error.detail
    assert_equal "req_token", error.request_id
  end

  def test_no_response_raises_a_connection_error
    error = retrieve_failing_with(NETWORK_ERROR)

    assert_instance_of TeachMeHipaa::APIConnectionError, error
    assert_nil error.status
    assert_instance_of Errno::ECONNREFUSED, error.cause
  end

  def test_a_timeout_raises_the_timeout_error
    error = retrieve_failing_with(READ_TIMEOUT)

    assert_instance_of TeachMeHipaa::APITimeoutError, error
    assert_kind_of TeachMeHipaa::APIConnectionError, error
    assert_instance_of Net::ReadTimeout, error.cause
  end

  def test_a_transport_raising_the_connection_error_itself_is_passed_through
    error = retrieve_failing_with(->(_request) { raise TeachMeHipaa::APITimeoutError, "proxy gave up" })

    assert_instance_of TeachMeHipaa::APITimeoutError, error
    assert_equal "proxy gave up", error.message
  end

  private

  def retrieve_failing_with(reply)
    transport = scripted_transport
    transport.replace("GET", LEARNER_PATH, reply)
    assert_raises(TeachMeHipaa::Error) do
      build_client(transport, organization_id: ORG_ID, max_retries: 0).learners.retrieve(LEARNER_ID)
    end
  end
end
