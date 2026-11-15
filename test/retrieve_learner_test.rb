# frozen_string_literal: true

require_relative "test_helper"

class RetrieveLearnerTest < Minitest::Test
  include ClientHelpers

  def setup
    @transport = scripted_transport
  end

  def test_client_retrieves_a_learner_by_id
    learner = build_client(@transport).learners.retrieve(LEARNER_ID)

    assert_instance_of TeachMeHipaa::Learner, learner
    assert_equal LEARNER_ID, learner.learner_id
    assert_equal "ana@example.com", learner.email
    assert_equal "Ana Lima", learner.name
    assert_equal "hr-123", learner.external_id
    assert_equal "in_progress", learner.status
    assert_equal "hipaa-essentials", learner.course.course_id
    assert_equal "HIPAA Essentials", learner.course.title
    assert_equal Time.utc(2026, 11, 2, 10, 30), learner.started_at
    assert_nil learner.completed_at
    assert_nil learner.certificate
  end

  def test_sends_the_access_token_and_asks_for_json
    build_client(@transport).learners.retrieve(LEARNER_ID)

    request = only(@transport.requests_to("GET", LEARNER_PATH))

    assert_equal "Bearer #{ACCESS_TOKEN}", request.headers["authorization"]
    assert_equal "application/json", request.headers["accept"]
  end

  def test_returned_learner_exposes_its_response_metadata
    learner = build_client(@transport).learners.retrieve(LEARNER_ID)

    assert_equal 200, learner.last_response.status
    assert_equal REQUEST_ID, learner.last_response.request_id
    assert_equal ETAG, learner.last_response.etag
    assert_equal "application/json", learner.last_response.headers["content-type"]
  end

  def test_response_header_names_are_read_case_insensitively
    reply = FakeTransport::Reply.json(
      LEARNER_JSON, headers: { "X-Request-Id" => REQUEST_ID, "ETag" => ETAG }
    )
    @transport.replace("GET", LEARNER_PATH, reply)

    learner = build_client(@transport).learners.retrieve(LEARNER_ID)

    assert_equal REQUEST_ID, learner.last_response.request_id
    assert_equal ETAG, learner.last_response.etag
  end

  def test_reads_the_certificate_when_the_learner_has_one
    reply = FakeTransport::Reply.json(
      LEARNER_JSON.merge("status" => "compliant", "certificate" => CERTIFICATE_JSON),
    )
    @transport.replace("GET", LEARNER_PATH, reply)

    certificate = build_client(@transport).learners.retrieve(LEARNER_ID).certificate

    assert_instance_of TeachMeHipaa::LearnerCertificate, certificate
    assert_equal "crt_01JD8Z4N3QX5V7W9Y2B4C6D8EH", certificate.certificate_id
    assert_equal Time.utc(2026, 11, 10, 15), certificate.issued_at
    assert_equal Time.utc(2027, 11, 10, 15), certificate.expires_at
    assert_equal "https://teachmehipaa.com/verify/crt_01JD8Z4N3QX5V7W9Y2B4C6D8EH", certificate.verify_url
    assert_nil certificate.last_response
  end

  def test_passes_the_course_as_a_query_parameter
    build_client(@transport).learners.retrieve(LEARNER_ID, course_id: "hipaa-advanced")

    request = only(@transport.requests_to("GET", LEARNER_PATH))

    assert_equal "courseId=hipaa-advanced", URI(request.url).query
  end

  def test_omits_the_course_when_not_given
    build_client(@transport).learners.retrieve(LEARNER_ID)

    assert_nil URI(only(@transport.requests_to("GET", LEARNER_PATH)).url).query
  end

  def test_escapes_the_learner_id_in_the_path
    @transport.on("GET", "/organizations/#{ORG_ID}/learners/a%2Fb", FakeTransport::Reply.json(LEARNER_JSON))

    build_client(@transport).learners.retrieve("a/b")

    assert_equal "https://api.tme.so/v1/organizations/#{ORG_ID}/learners/a%2Fb", @transport.requests.last.url
  end

  def test_keeps_unknown_fields_and_new_status_values
    reply = FakeTransport::Reply.json(
      LEARNER_JSON.merge("status" => "on_leave", "department" => "Billing"),
    )
    @transport.replace("GET", LEARNER_PATH, reply)

    learner = build_client(@transport).learners.retrieve(LEARNER_ID)

    assert_equal "on_leave", learner.status
    assert_equal "Billing", learner["department"]
    assert_equal "Billing", learner.to_h[:department]
  end

  def test_converts_to_a_hash_with_snake_case_keys
    learner = build_client(@transport).learners.retrieve(LEARNER_ID)

    assert_equal(
      {
        learner_id: LEARNER_ID, email: "ana@example.com", name: "Ana Lima", external_id: "hr-123",
        status: TeachMeHipaa::LearnerStatus::IN_PROGRESS,
        course: { course_id: "hipaa-essentials", title: "HIPAA Essentials" },
        invited_at: Time.utc(2026, 11, 1, 9), started_at: Time.utc(2026, 11, 2, 10, 30),
        completed_at: nil, due_at: Time.utc(2026, 12, 1), certificate: nil
      },
      learner.to_h,
    )
    assert_equal "ana@example.com", learner[:email]
    assert_equal "ana@example.com", learner["email"]
  end

  def test_a_returned_learner_is_immutable
    learner = build_client(@transport).learners.retrieve(LEARNER_ID)

    assert_predicate learner, :frozen?
    refute_respond_to learner, :email=
  end

  def test_a_problem_response_raises_with_its_fields
    reply = FakeTransport::Reply.json(
      { "title" => "Not Found", "status" => 404, "code" => "not_found", "detail" => "No such learner." },
      status: 404, content_type: "application/problem+json",
      headers: { "x-request-id" => REQUEST_ID }
    )
    @transport.replace("GET", LEARNER_PATH, reply)

    error = assert_raises(TeachMeHipaa::Error) { build_client(@transport).learners.retrieve(LEARNER_ID) }

    assert_equal [404, "not_found"], [error.status, error.code]
    assert_equal ["Not Found", "No such learner."], [error.title, error.detail]
    assert_equal REQUEST_ID, error.request_id
    assert_equal REQUEST_ID, error.headers["x-request-id"]
    assert_equal "No such learner. (request id: #{REQUEST_ID})", error.message
  end

  def test_a_non_json_success_raises_instead_of_failing_to_parse
    reply = FakeTransport::Reply.new(
      status: 200, body: "<!doctype html><html></html>", headers: {},
      content_type: "text/html"
    )
    @transport.replace("GET", LEARNER_PATH, reply)

    error = assert_raises(TeachMeHipaa::Error) { build_client(@transport).learners.retrieve(LEARNER_ID) }

    assert_equal 200, error.status
    assert_match(%r{text/html}, error.message)
    assert_equal "<!doctype html><html></html>", error.body
  end

  def test_sends_extra_headers_and_timeout_from_request_options
    build_client(@transport).learners.retrieve(
      LEARNER_ID, request_options: { headers: { "X-Request-Id" => "partner-trace-1" }, timeout: 5 }
    )

    request = only(@transport.requests_to("GET", LEARNER_PATH))

    assert_equal "partner-trace-1", request.headers["x-request-id"]
    assert_equal "Bearer #{ACCESS_TOKEN}", request.headers["authorization"]
    assert_in_delta 5.0, request.timeout
  end

  def test_sends_a_custom_request_id_on_every_attempt
    transport = FakeTransport.new
    transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    transport.on("GET", LEARNER_PATH, Fixtures.problem(503, "temporarily_unavailable"))
    transport.on("GET", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))

    build_client(transport, organization_id: ORG_ID, sleep: FakeSleep.new)
      .learners.retrieve(LEARNER_ID, request_options: { request_id: "sync-job-42.attempt-1" })

    sent = transport.requests_to("GET", LEARNER_PATH).map { |r| r.headers["x-request-id"] }

    assert_equal ["sync-job-42.attempt-1"] * 2, sent
  end

  def test_rejects_an_unknown_request_option
    error = assert_raises(ArgumentError) do
      build_client(@transport).learners.retrieve(LEARNER_ID, request_options: { retries: 3 })
    end

    assert_match(/retries/, error.message)
  end
end
