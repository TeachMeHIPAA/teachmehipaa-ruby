# frozen_string_literal: true

require_relative "test_helper"

class OperationsTest < Minitest::Test
  include ClientHelpers

  Reply = FakeTransport::Reply

  ORG = "/organizations/#{ORG_ID}".freeze
  OPERATION_ID = "0b7d4a8e-5c1f-4e2a-9d3b-6f8a1c2e4b7d"
  # Research api-sdk-surface.md §8: organizations/{orgId}/operations/{id}.
  OPERATION_NAME = "organizations/#{ORG_ID}/operations/#{OPERATION_ID}".freeze
  POLL_PATH = "#{ORG}/operations/#{OPERATION_ID}".freeze
  SUBSCRIPTION_ID = "whs_01JD8K2M4N6P8R0T2V4X6Z8B0D"
  TEST_DELIVERY_PATH = "#{ORG}/webhook-subscriptions/#{SUBSCRIPTION_ID}:test".freeze
  REDRIVE_PATH = "#{ORG}/webhook-subscriptions/#{SUBSCRIPTION_ID}:redrive".freeze

  # An export's 202: a done Operation whose response is the monorepo's
  # ExportArtifact (api-contracts bulk.schemas.ts), the CSV in base64.
  EXPORT_OPERATION = {
    "name" => OPERATION_NAME,
    "done" => true,
    "metadata" => { "kind" => "enrollments:export" },
    "response" => {
      "format" => "csv",
      "contentType" => "text/csv; charset=utf-8",
      "filename" => "enrollments-#{ORG_ID}.csv",
      "rowCount" => 2,
      "dataBase64" =>
        "bGVhcm5lcklkLGVtYWlsLG5hbWUNCnN1Yl8wMUpEODBBQjJDM0Q0RTVGNkc3SDhKOUsw" \
        "TSxhbmFAZXhhbXBsZS5jb20sIkV4YW1wbGUsIEFuYSINCnN1Yl8wMUpEODBBQjJDM0Q0" \
        "RTVGNkc3SDhKOUswTixqb3NlQGV4YW1wbGUuY29tLEpvc8OpIE7DusOxZXoNCg==",
    },
  }.freeze
  # What EXPORT_OPERATION's dataBase64 decodes to (checked with base64 -d):
  # RFC 4180, CRLF, UTF-8.
  EXPORTED_CSV =
    "learnerId,email,name\r\n" \
    "sub_01JD80AB2C3D4E5F6G7H8J9K0M,ana@example.com,\"Example, Ana\"\r\n" \
    "sub_01JD80AB2C3D4E5F6G7H8J9K0N,jose@example.com,José Núñez\r\n"

  # A Test delivery's 202: pending until the webhook worker settles it.
  PENDING_OPERATION = { "name" => OPERATION_NAME, "done" => false }.freeze
  # The worker's settle on a 2xx from the endpoint (§8: response._tag).
  SENT_OPERATION = {
    "name" => OPERATION_NAME, "done" => true, "response" => { "_tag" => "sent", "responseStatus" => 200 }
  }.freeze
  # dev#/components/schemas/Operation: a done Operation with a problem.
  FAILED_OPERATION = {
    "name" => OPERATION_NAME,
    "done" => true,
    "error" => {
      "title" => "Temporarily unavailable",
      "status" => 503,
      "code" => "temporarily_unavailable",
      "detail" => "Webhook delivery is paused. Try again later.",
      "errors" => [{ "path" => "url", "message" => "unreachable" }],
    },
  }.freeze

  def setup
    @transport = FakeTransport.new
    @transport.on("POST", "/auth/token", Reply.json(token_json))
    @clock = FakeClock.new
    @sleep = FakeSleep.new(@clock)
  end

  def test_a_done_operation_returns_from_wait_without_a_request
    @transport.on("POST", "#{ORG}/enrollments:export", Reply.json(EXPORT_OPERATION, status: 202))

    operation = client.enrollments.export(format: "csv")
    finished = operation.wait

    assert_same operation, finished
    assert finished.done
    assert_equal OPERATION_NAME, finished.name
    assert_equal 202, finished.last_response.status
    assert_equal 2, @transport.requests.length
    assert_empty @sleep.waits
  end

  def test_a_pending_operation_polls_until_it_is_done
    pending_then(Reply.json(PENDING_OPERATION), Reply.json(PENDING_OPERATION),
                 Reply.json(SENT_OPERATION, headers: { "x-request-id" => "req_poll_3" }))

    operation = client.webhook_subscriptions.test(SUBSCRIPTION_ID)
    finished = operation.wait

    refute operation.done
    assert finished.done
    assert_equal "req_poll_3", finished.last_response.request_id
    assert_equal 3, polls.length
    assert_equal 3, @sleep.waits.length
    assert_equal "Bearer #{ACCESS_TOKEN}", polls.first.headers["authorization"]
  end

  def test_polls_back_off_from_one_second_doubling_with_jitter_to_a_ten_second_cap
    pending_then(*Array.new(7) { Reply.json(PENDING_OPERATION) }, Reply.json(SENT_OPERATION))

    client.webhook_subscriptions.test(SUBSCRIPTION_ID).wait

    # Ceilings 1, 2, 4, 8, 10, 10, 10, 10 s; jitter keeps each within
    # 50-100% of its ceiling, and never below the 1 s interval.
    ranges = [[1, 1], [1, 2], [2, 4], [4, 8], [5, 10], [5, 10], [5, 10], [5, 10]]

    assert_equal ranges.length, @sleep.waits.length
    @sleep.waits.zip(ranges).each do |waited, (low, high)|
      assert_kind_of Float, waited
      assert_operator waited, :>=, low
      assert_operator waited, :<=, high
    end
  end

  def test_polls_start_from_the_interval_given
    pending_then(Reply.json(PENDING_OPERATION), Reply.json(SENT_OPERATION))

    client.webhook_subscriptions.test(SUBSCRIPTION_ID).wait(interval: 0.25)

    assert_in_delta 0.25, @sleep.waits[0]
    assert_operator @sleep.waits[1], :>=, 0.25
    assert_operator @sleep.waits[1], :<=, 0.5
  end

  def test_an_interval_longer_than_the_cap_is_kept
    pending_then(Reply.json(PENDING_OPERATION), Reply.json(SENT_OPERATION))

    client.webhook_subscriptions.test(SUBSCRIPTION_ID).wait(interval: 15)

    assert_equal [15.0, 15.0], @sleep.waits
  end

  def test_wait_raises_operation_timeout_error_after_a_last_poll_at_the_deadline
    pending_then(Reply.json(PENDING_OPERATION, headers: { "x-request-id" => "req_poll_last" }))
    operation = client.webhook_subscriptions.test(SUBSCRIPTION_ID)

    error = assert_raises(TeachMeHipaa::OperationTimeoutError) { operation.wait(timeout: 5) }

    assert_kind_of TeachMeHipaa::Error, error
    assert_equal "Operation #{OPERATION_NAME} was not done after 5 s (request id: req_poll_last)", error.message
    assert_equal "req_poll_last", error.request_id
    refute error.operation.done
    assert_equal OPERATION_NAME, error.operation.name
    assert_in_delta 5.0, @sleep.waits.sum
    assert_equal @sleep.waits.length, polls.length
  end

  def test_wait_given_no_time_raises_operation_timeout_error_without_a_poll
    pending_then(Reply.json(SENT_OPERATION))
    operation = client.webhook_subscriptions.test(SUBSCRIPTION_ID)

    error = assert_raises(TeachMeHipaa::OperationTimeoutError) { operation.wait(timeout: 0) }

    assert_same operation, error.operation
    assert_empty polls
  end

  def test_wait_raises_operation_failed_error_with_the_problem
    pending_then(Reply.json(FAILED_OPERATION, headers: { "x-request-id" => "req_poll_1" }))
    operation = client.webhook_subscriptions.test(SUBSCRIPTION_ID)

    error = assert_raises(TeachMeHipaa::OperationFailedError) { operation.wait }

    assert_kind_of TeachMeHipaa::Error, error
    assert_equal "Webhook delivery is paused. Try again later. (request id: req_poll_1)", error.message
    assert_equal 503, error.status
    assert_equal "temporarily_unavailable", error.code
    assert_equal "Temporarily unavailable", error.title
    assert_equal "Webhook delivery is paused. Try again later.", error.detail
    assert_equal [TeachMeHipaa::FieldError.new(path: "url", message: "unreachable")], error.errors
    assert_equal "req_poll_1", error.request_id
    assert error.operation.done
  end

  def test_an_operation_already_done_with_an_error_raises_without_a_request
    @transport.on("POST", TEST_DELIVERY_PATH, Reply.json(FAILED_OPERATION, status: 202))
    operation = client.webhook_subscriptions.test(SUBSCRIPTION_ID)

    error = assert_raises(TeachMeHipaa::OperationFailedError) { operation.wait }

    assert_same operation, error.operation
    assert_empty polls
  end

  def test_export_result_returns_the_csv_text_file_name_and_row_count
    @transport.on("POST", "#{ORG}/enrollments:export", Reply.json(EXPORT_OPERATION, status: 202))

    result = client.enrollments.export(format: "csv").export_result

    assert_equal TeachMeHipaa::ExportResult.new(csv: EXPORTED_CSV, filename: "enrollments-#{ORG_ID}.csv",
                                                row_count: 2), result
    assert_equal Encoding::UTF_8, result.csv.encoding
  end

  {
    "certificates" => ->(client) { client.certificates.export(format: "csv") },
    "learners" => ->(client) { client.learners.export(format: "csv", course_id: "hipaa-2026") },
  }.each do |resource, export|
    define_method("test_export_result_reads_the_#{resource}_export_the_same_way") do
      @transport.on("POST", "#{ORG}/#{resource}:export", Reply.json(EXPORT_OPERATION, status: 202))

      assert_equal EXPORTED_CSV, export.call(client).export_result.csv
    end
  end

  def test_export_result_reads_an_export_retrieved_by_id
    @transport.on("GET", POLL_PATH, Reply.json(EXPORT_OPERATION))

    assert_equal EXPORTED_CSV, client.operations.retrieve(OPERATION_ID).export_result.csv
  end

  def test_an_export_result_keeps_the_csv_out_of_inspect
    @transport.on("POST", "#{ORG}/enrollments:export", Reply.json(EXPORT_OPERATION, status: 202))

    inspected = client.enrollments.export(format: "csv").export_result.inspect

    refute_includes inspected, "ana@example.com"
    assert_includes inspected, "enrollments-#{ORG_ID}.csv"
  end

  def test_export_result_refuses_an_operation_that_is_not_done
    @transport.on("GET", POLL_PATH, Reply.json(PENDING_OPERATION))
    operation = client.operations.retrieve(OPERATION_ID)

    error = assert_raises(ArgumentError) { operation.export_result }

    assert_equal "Operation #{OPERATION_NAME} is not done; call wait first", error.message
  end

  def test_export_result_refuses_an_operation_that_is_not_an_export
    @transport.on("GET", POLL_PATH, Reply.json(SENT_OPERATION))
    operation = client.operations.retrieve(OPERATION_ID)

    error = assert_raises(ArgumentError) { operation.export_result }

    assert_equal "Operation #{OPERATION_NAME} did not produce a CSV export", error.message
  end

  def test_export_result_raises_operation_failed_error_for_a_failed_export
    @transport.on("GET", POLL_PATH, Reply.json(FAILED_OPERATION))
    operation = client.operations.retrieve(OPERATION_ID)

    assert_raises(TeachMeHipaa::OperationFailedError) { operation.export_result }
  end

  def test_operation_id_from_name_reads_the_id_that_operations_retrieve_takes
    name = "organizations/org_acme/operations/0b7d4a8e-5c1f-4e2a-9d3b-6f8a1c2e4b7d"

    assert_equal "0b7d4a8e-5c1f-4e2a-9d3b-6f8a1c2e4b7d", TeachMeHipaa::Operation.operation_id_from_name(name)
  end

  [
    "0b7d4a8e-5c1f-4e2a-9d3b-6f8a1c2e4b7d",
    "organizations/org_acme/operations/",
    "organizations//operations/op_1",
    "organizations/org_acme/learners/sub_01JD80AB2C3D4E5F6G7H8J9K0M",
    "organizations/org_acme/operations/op_1/extra",
    "/organizations/org_acme/operations/op_1",
    "organizations/org_acme/operations/op_1\n",
  ].each_with_index do |name, index|
    define_method("test_operation_id_from_name_rejects_anything_but_an_operation_name_#{index}") do
      error = assert_raises(ArgumentError) { TeachMeHipaa::Operation.operation_id_from_name(name) }

      assert_includes error.message, "is not an Operation name"
    end
  end

  def test_wait_polls_the_operation_its_name_identifies
    other_id = "op_7Q2"
    other = PENDING_OPERATION.merge("name" => "organizations/#{ORG_ID}/operations/#{other_id}")
    @transport.on("POST", TEST_DELIVERY_PATH, Reply.json(other, status: 202))
    @transport.on("GET", "#{ORG}/operations/#{other_id}", Reply.json(other.merge("done" => true)))

    finished = client.webhook_subscriptions.test(SUBSCRIPTION_ID).wait

    assert finished.done
    assert_equal 1, @transport.requests_to("GET", "#{ORG}/operations/#{other_id}").length
  end

  def test_a_test_delivery_operation_reads_its_response_as_a_sent_delivery
    pending_then(Reply.json(SENT_OPERATION))

    finished = client.webhook_subscriptions.test(SUBSCRIPTION_ID).wait

    assert_instance_of TeachMeHipaa::WebhookDeliveryOperation, finished
    assert_kind_of TeachMeHipaa::Operation, finished
    assert_instance_of TeachMeHipaa::WebhookDeliverySent, finished.response
    assert_kind_of TeachMeHipaa::WebhookDeliveryResult, finished.response
    assert_equal "sent", finished.response.tag
    assert_equal 200, finished.response.response_status
  end

  def test_a_redrive_operation_reads_a_failed_delivery_with_its_last_status
    redrive_done("_tag" => "failed", "reason" => "endpoint_gone", "responseStatus" => 410)

    result = client.webhook_subscriptions.redrive(SUBSCRIPTION_ID).response

    assert_instance_of TeachMeHipaa::WebhookDeliveryFailed, result
    assert_equal ["failed", "endpoint_gone", 410], [result.tag, result.reason, result.response_status]
  end

  def test_a_redrive_operation_reads_a_failed_delivery_the_endpoint_never_answered
    redrive_done("_tag" => "failed", "reason" => "connection_refused")

    result = client.webhook_subscriptions.redrive(SUBSCRIPTION_ID).response

    assert_instance_of TeachMeHipaa::WebhookDeliveryFailed, result
    assert_equal "connection_refused", result.reason
    assert_nil result.response_status
  end

  def test_a_redrive_operation_reads_a_delivery_already_settled
    redrive_done("_tag" => "settled", "status" => "delivered")

    result = client.webhook_subscriptions.redrive(SUBSCRIPTION_ID).response

    assert_instance_of TeachMeHipaa::WebhookDeliverySettled, result
    assert_equal %w[settled delivered], [result.tag, result.status]
  end

  def test_a_delivery_result_with_an_unknown_tag_is_kept_not_rejected
    pending_then(Reply.json({ "name" => OPERATION_NAME, "done" => true,
                              "response" => { "_tag" => "skipped", "why" => "nothing to deliver" } }))

    result = client.webhook_subscriptions.test(SUBSCRIPTION_ID).wait.response

    assert_instance_of TeachMeHipaa::WebhookDeliveryResult::Unknown, result
    assert_kind_of TeachMeHipaa::WebhookDeliveryResult, result
    assert_equal "skipped", result.tag
    assert_equal "nothing to deliver", result["why"]
  end

  def test_an_operation_compares_by_its_fields_not_the_client_that_read_it
    @transport.on("GET", POLL_PATH, Reply.json(EXPORT_OPERATION))
    operation = client.operations.retrieve(OPERATION_ID)

    assert_equal TeachMeHipaa::Operation.new(EXPORT_OPERATION), operation
    assert_equal %i[name done metadata response error], operation.to_h.keys
  end

  private

  def redrive_done(response)
    @transport.on("POST", REDRIVE_PATH,
                  Reply.json({ "name" => OPERATION_NAME, "done" => true, "response" => response }, status: 202))
  end

  def client
    build_client(@transport, organization_id: ORG_ID, clock: @clock, sleep: @sleep, max_retries: 0)
  end

  # A Test delivery that starts pending, then polls through +replies+.
  def pending_then(*replies)
    @transport.on("POST", TEST_DELIVERY_PATH, Reply.json(PENDING_OPERATION, status: 202))
    replies.each { |reply| @transport.on("GET", POLL_PATH, reply) }
  end

  def polls
    @transport.requests_to("GET", POLL_PATH)
  end
end
