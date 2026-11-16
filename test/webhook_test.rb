# frozen_string_literal: true

require_relative "test_helper"

# Webhook Delivery verification and test-header signing (ADR-0005).
class WebhookTest < Minitest::Test
  # The shared cross-SDK vector (~/scratch/tmh-sdks/_shared/webhook-vector.json),
  # signed by the platform's own signer, not this SDK: `bun platform-sign.ts`
  # run in the monorepo calls packages/auth-s2s `signRequest` on
  # packages/webhooks `canonicalizeEventBody(envelope)`, and a node:crypto-only
  # replica of auth-s2s canonical.ts produced the same hex.
  SECRET = "4l28+FYKZo2O57actVGINwR/Xyhzt3OtqCipV81/Zd0="
  KEY_ID = "WHSEC-7KQ2-M4XD-9RTB-H3VN"
  PATH = "/hooks/tmh?source=teachmehipaa"
  ENDPOINT_URL = "https://partner.example.com/hooks/tmh?source=teachmehipaa"
  EVENT_TIMESTAMP = "2026-11-15T16:31:32.123Z"
  EVENT_ID = "evt_01JCZ8Y2K5V3M7Q9R4T6W8X0AB"
  EVENT_BODY =
    '{"data":{"courseId":"hipaa-basics-2026","email":"zoë.müller@example.com",' \
    '"externalId":"hr-123","learnerId":"lrn_4h7j2k",' \
    '"occurredAt":"2026-11-15T16:31:30.000Z","status":"certified"},' \
    '"eventId":"evt_01JCZ8Y2K5V3M7Q9R4T6W8X0AB","eventType":"learner.certified",' \
    '"occurredAt":"2026-11-15T16:31:30.000Z","orgId":"org_9f3k2m"}'
  EVENT_BODY_HASH = "0a849105d2fea53433e3284d0dc6dee83ebccdf6e64088bf34bf3b537b6e640b"
  EVENT_SIGNATURE = "c2a0fd14bca6c361c44e84a5b3bf0378b00c49a533636a229c2b6972073b618a"
  EVENT_HEADERS = {
    "x-tmh-key-id" => KEY_ID,
    "x-tmh-timestamp" => EVENT_TIMESTAMP,
    "x-tmh-signature" => EVENT_SIGNATURE,
    "x-tmh-body-hash" => EVENT_BODY_HASH,
    "x-tmh-event-type" => "learner.certified",
    "x-tmh-event-id" => EVENT_ID,
    "content-type" => "application/json",
  }.freeze

  # What a signer that wrongly base64-decodes the Signing secret produces for
  # the same Delivery (the vector's `signatureWithBase64DecodedKey`).
  SIGNATURE_WITH_DECODED_KEY = "26c88e3993dc44d1f52949f6bc1a9061c5e3e9c0b12caf04934e2e4ea3814f2d"

  # The vector's Test delivery, signed the same way: the body the platform's
  # `:test` route builds, canonicalized.
  TEST_DELIVERY_TIMESTAMP = "2026-11-15T16:40:05.000Z"
  TEST_DELIVERY_EVENT_ID = "3f1c9a52-7d4e-4b8a-9c21-5e6f7a8b9c0d"
  TEST_DELIVERY_BODY = '{"subscriptionId":"whs_2b8f4c1d","test":true}'
  TEST_DELIVERY_BODY_HASH = "42879a05e13a5dfba51eee07c2fef4814ec6009091f1389a8db4403661ce6a66"
  TEST_DELIVERY_SIGNATURE = "b7baa3ae58a738d025adf4e27ce7af833ac6085f5cb1cc5fc8ff1addb191c3b9"
  TEST_DELIVERY_HEADERS = {
    "x-tmh-key-id" => KEY_ID,
    "x-tmh-timestamp" => TEST_DELIVERY_TIMESTAMP,
    "x-tmh-signature" => TEST_DELIVERY_SIGNATURE,
    "x-tmh-body-hash" => TEST_DELIVERY_BODY_HASH,
    "x-tmh-event-type" => "learner.certified",
    "x-tmh-event-id" => TEST_DELIVERY_EVENT_ID,
    "content-type" => "application/json",
  }.freeze

  AT_EVENT_TIME = Time.utc(2026, 11, 15, 16, 31, 40)

  def construct(payload = EVENT_BODY, headers = EVENT_HEADERS, secret: SECRET, path: PATH,
                received_at: AT_EVENT_TIME, **)
    TeachMeHipaa::Webhook.construct_event(payload, headers, secret, path, received_at:, **)
  end

  def test_verifies_a_delivery_signed_by_the_platform_and_returns_its_event
    event = construct(EVENT_BODY.b)

    assert_instance_of TeachMeHipaa::EventLearnerCertified, event
    assert_kind_of TeachMeHipaa::Event, event
    assert_equal EVENT_ID, event.event_id
    assert_equal "learner.certified", event.event_type
    assert_equal "org_9f3k2m", event.org_id
    assert_equal Time.utc(2026, 11, 15, 16, 31, 30), event.occurred_at
    assert_equal "lrn_4h7j2k", event.data.learner_id
    assert_equal "zoë.müller@example.com", event.data.email
    assert_equal "hr-123", event.data.external_id
    assert_equal "hipaa-basics-2026", event.data.course_id
    assert_equal "certified", event.data.status
  end

  def rejection(payload = EVENT_BODY, headers = EVENT_HEADERS, **)
    error = assert_raises(TeachMeHipaa::WebhookSignatureError) { construct(payload, headers, **) }
    assert_kind_of TeachMeHipaa::Error, error
    error
  end

  def headers_without(name, headers = EVENT_HEADERS)
    headers.except(name)
  end

  def tampered_body
    EVENT_BODY.sub("hr-123", "hr-124")
  end

  def test_rejects_a_tampered_body_without_a_body_hash_header
    error = rejection(tampered_body, headers_without("x-tmh-body-hash"))

    assert_equal "signature_mismatch", error.code
  end

  def test_rejects_a_delivery_verified_against_the_wrong_path
    error = rejection(path: "/hooks/tmh")

    assert_equal "signature_mismatch", error.code
    assert_includes error.message, "exact request path"
  end

  def test_rejects_a_delivery_verified_with_the_wrong_signing_secret
    error = rejection(secret: "Zm9vYmFyYmF6cXV4cXV1eGNvcmdlZ3JhdWx0Z2FycGx5")

    assert_equal "signature_mismatch", error.code
  end

  def test_rejects_a_signature_made_with_the_base64_decoded_signing_secret
    error = rejection(EVENT_BODY, EVENT_HEADERS.merge("x-tmh-signature" => SIGNATURE_WITH_DECODED_KEY))

    assert_equal "signature_mismatch", error.code
  end

  def test_rejects_a_malformed_signature
    ["not-hex", "é" * 64, EVENT_SIGNATURE.upcase, "#{EVENT_SIGNATURE}00"].each do |signature|
      error = rejection(EVENT_BODY, EVENT_HEADERS.merge("x-tmh-signature" => signature))

      assert_equal "signature_mismatch", error.code, signature
    end
  end

  def test_signature_errors_never_carry_the_body_or_headers
    error = rejection(tampered_body, headers_without("x-tmh-body-hash"))

    assert_nil error.body
    assert_empty error.headers
    assert_nil error.status
    assert_nil error.request_id
    refute_includes error.message, "zoë"
    refute_includes error.inspect, "zoë"
  end

  def test_rejects_a_delivery_more_than_5_minutes_old
    error = rejection(received_at: Time.iso8601("2026-11-15T16:36:32.124Z"))

    assert_equal "timestamp_outside_tolerance", error.code
  end

  def test_rejects_a_delivery_more_than_5_minutes_in_the_future
    error = rejection(received_at: Time.iso8601("2026-11-15T16:26:32.122Z"))

    assert_equal "timestamp_outside_tolerance", error.code
  end

  def test_accepts_a_delivery_exactly_5_minutes_off
    %w[2026-11-15T16:36:32.123Z 2026-11-15T16:26:32.123Z].each do |received_at|
      assert_instance_of TeachMeHipaa::EventLearnerCertified, construct(received_at: Time.iso8601(received_at))
    end
  end

  def test_honors_a_custom_tolerance_in_seconds
    error = rejection(tolerance: 5, received_at: Time.utc(2026, 11, 15, 16, 31, 40))

    assert_equal "timestamp_outside_tolerance", error.code
  end

  def test_compares_timestamps_across_utc_offsets
    event = construct(received_at: Time.iso8601("2026-11-15T11:31:40.000-05:00"))

    assert_instance_of TeachMeHipaa::EventLearnerCertified, event
  end

  def test_checks_the_signature_before_the_timestamp
    # A forgery must never be reported as merely late.
    error = rejection(tampered_body, headers_without("x-tmh-body-hash"), received_at: Time.utc(2027, 1, 1))

    assert_equal "signature_mismatch", error.code
  end

  def test_rejects_a_timestamp_that_is_not_an_iso_date_time
    ["1763224292", "2026-11-15 16:31:32Z", "2026-13-15T16:31:32Z", "2026-11-15T16:31:32"].each do |timestamp|
      error = rejection(EVENT_BODY, EVENT_HEADERS.merge("x-tmh-timestamp" => timestamp))

      assert_equal "invalid_timestamp", error.code, timestamp
    end
  end

  def test_refuses_a_tolerance_that_is_not_positive
    [0, -1, Float::NAN].each do |tolerance|
      error = assert_raises(ArgumentError) { construct(tolerance:) }

      assert_includes error.message, "tolerance"
    end
  end

  def test_rejects_a_tampered_body_by_its_body_hash_header
    error = rejection(tampered_body)

    assert_equal "body_hash_mismatch", error.code
    assert_includes error.message, "raw request body"
  end

  def test_rejects_a_delivery_without_a_required_header
    %w[x-tmh-signature x-tmh-timestamp].each do |name|
      [headers_without(name), EVENT_HEADERS.merge(name => "")].each do |headers|
        error = rejection(EVENT_BODY, headers)

        assert_equal "missing_header", error.code
        assert_includes error.message, name
      end
    end
  end

  def test_accepts_header_names_in_any_case
    headers = {
      "X-Tmh-Timestamp" => EVENT_TIMESTAMP,
      "X-TMH-SIGNATURE" => EVENT_SIGNATURE,
      "X-Tmh-Body-Hash" => EVENT_BODY_HASH,
    }

    assert_instance_of TeachMeHipaa::EventLearnerCertified, construct(EVENT_BODY, headers)
  end

  def test_accepts_a_rack_env
    env = {
      "REQUEST_METHOD" => "POST",
      "PATH_INFO" => "/hooks/tmh",
      "QUERY_STRING" => "source=teachmehipaa",
      "CONTENT_TYPE" => "application/json",
      "HTTP_X_TMH_TIMESTAMP" => EVENT_TIMESTAMP,
      "HTTP_X_TMH_SIGNATURE" => EVENT_SIGNATURE,
      "HTTP_X_TMH_BODY_HASH" => EVENT_BODY_HASH,
      "rack.input" => Object.new,
    }

    assert_instance_of TeachMeHipaa::EventLearnerCertified, construct(EVENT_BODY, env)
  end

  def test_reads_the_body_hash_header_from_a_rack_env
    env = { "HTTP_X_TMH_TIMESTAMP" => EVENT_TIMESTAMP, "HTTP_X_TMH_SIGNATURE" => EVENT_SIGNATURE,
            "HTTP_X_TMH_BODY_HASH" => EVENT_BODY_HASH }

    assert_equal "body_hash_mismatch", rejection(tampered_body, env).code
  end

  def test_accepts_the_full_request_url_in_place_of_the_path
    assert_instance_of TeachMeHipaa::EventLearnerCertified, construct(path: ENDPOINT_URL)
  end

  def test_refuses_a_path_that_is_neither_a_path_nor_a_url
    ["hooks/tmh?source=teachmehipaa", "https://exa mple.com/x"].each do |path|
      error = assert_raises(ArgumentError) { construct(path:) }

      assert_includes error.message, "request path"
    end
  end

  def test_refuses_a_missing_signing_secret
    ["", nil].each do |secret|
      error = assert_raises(ArgumentError) { construct(secret:) }

      assert_includes error.message, "Signing secret"
    end
  end

  def test_returns_a_test_delivery_as_its_own_type
    delivery = construct(TEST_DELIVERY_BODY, TEST_DELIVERY_HEADERS, received_at: Time.utc(2026, 11, 15, 16, 40, 6))

    assert_instance_of TeachMeHipaa::TestDelivery, delivery
    assert_equal "whs_2b8f4c1d", delivery.subscription_id
    assert delivery.test
  end

  def test_rejects_the_test_delivery_signed_with_the_base64_decoded_signing_secret
    headers = TEST_DELIVERY_HEADERS.merge(
      "x-tmh-signature" => "f1179ed3147ae1cafca03770401dca485476bcb0183458b2a0f91b0deebf318c",
    )

    error = rejection(TEST_DELIVERY_BODY, headers, received_at: Time.utc(2026, 11, 15, 16, 40, 6))

    assert_equal "signature_mismatch", error.code
  end

  def test_generates_the_headers_the_platform_sent_for_the_vectors_event
    headers = TeachMeHipaa::Webhook.generate_test_headers(
      payload: EVENT_BODY, secret: SECRET, path: PATH, timestamp: Time.iso8601(EVENT_TIMESTAMP),
      event_type: "learner.certified", event_id: EVENT_ID, key_id: KEY_ID
    )

    assert_equal EVENT_HEADERS, headers
  end

  def test_generates_the_headers_the_platform_sent_for_the_vectors_test_delivery
    headers = TeachMeHipaa::Webhook.generate_test_headers(
      payload: TEST_DELIVERY_BODY.b, secret: SECRET, path: ENDPOINT_URL,
      timestamp: Time.iso8601("2026-11-15T17:40:05+01:00"),
      event_type: "learner.certified", event_id: TEST_DELIVERY_EVENT_ID, key_id: KEY_ID
    )

    assert_equal TEST_DELIVERY_HEADERS, headers
  end

  def test_leaves_out_the_identifying_headers_it_was_not_given
    headers = TeachMeHipaa::Webhook.generate_test_headers(
      payload: TEST_DELIVERY_BODY, secret: SECRET, path: PATH, timestamp: Time.utc(2026, 11, 15, 16, 40, 5),
    )

    assert_equal(
      {
        "x-tmh-timestamp" => TEST_DELIVERY_TIMESTAMP,
        "x-tmh-signature" => TEST_DELIVERY_SIGNATURE,
        "x-tmh-body-hash" => TEST_DELIVERY_BODY_HASH,
        "content-type" => "application/json",
      },
      headers,
    )
  end

  def test_generated_headers_verify_now
    headers = TeachMeHipaa::Webhook.generate_test_headers(payload: TEST_DELIVERY_BODY, secret: SECRET, path: PATH)

    delivery = TeachMeHipaa::Webhook.construct_event(TEST_DELIVERY_BODY, headers, SECRET, PATH)

    assert_instance_of TeachMeHipaa::TestDelivery, delivery
    assert_equal "whs_2b8f4c1d", delivery.subscription_id
  end

  def test_returns_an_event_of_a_type_not_in_the_catalog_as_an_unknown_event
    body = '{"data":{"badge":"gold","learnerId":"lrn_4h7j2k"},"eventId":"evt_01JCZ9000000000000000000AB",' \
           '"eventType":"learner.promoted","occurredAt":"2026-11-15T16:31:30.000Z","orgId":"org_9f3k2m"}'
    headers = TeachMeHipaa::Webhook.generate_test_headers(
      payload: body, secret: SECRET, path: PATH, timestamp: Time.iso8601(EVENT_TIMESTAMP),
    )

    event = construct(body, headers)

    assert_instance_of TeachMeHipaa::UnknownEvent, event
    assert_kind_of TeachMeHipaa::Event, event
    assert_equal "learner.promoted", event.event_type
    assert_equal "evt_01JCZ9000000000000000000AB", event.event_id
    assert_equal({ "badge" => "gold", "learnerId" => "lrn_4h7j2k" }, event.data)
  end

  def test_webhooks_are_reachable_from_the_client_without_a_request
    transport = FakeTransport.new(Fixtures::LIVE_BASE)
    client = TeachMeHipaa::Client.new(client_id: Fixtures::CLIENT_ID, client_secret: Fixtures::CLIENT_SECRET,
                                      transport:)

    assert_same TeachMeHipaa::Webhook, client.webhooks
    event = client.webhooks.construct_event(EVENT_BODY, EVENT_HEADERS, SECRET, PATH, received_at: AT_EVENT_TIME)

    assert_instance_of TeachMeHipaa::EventLearnerCertified, event
    assert_empty transport.requests
  end
end

# The verifier hardcodes ADR-0005's recipe. If the vendored IR ever describes
# a different one, these fail and the verifier must change with it.
class WebhookSigningRecipeTest < Minitest::Test
  SIGNING = JSON.parse(File.read(File.expand_path("../openapi/sdk-ir.json", __dir__), encoding: "UTF-8")).dig("events",
                                                                                                              "signing")

  def test_the_ir_describes_the_recipe_this_library_verifies
    assert_equal(
      {
        "algorithm" => "hmacSha256Hex",
        "canonical" => {
          "parts" => [
            { "kind" => "literal", "value" => "POST" },
            { "kind" => "pathAndQuery" },
            { "kind" => "header", "name" => "x-tmh-timestamp" },
            { "kind" => "bodySha256Hex" },
          ],
          "separator" => "\n",
        },
        "headers" => {
          "bodyHash" => "x-tmh-body-hash",
          "eventId" => "x-tmh-event-id",
          "eventType" => "x-tmh-event-type",
          "keyId" => "x-tmh-key-id",
          "signature" => "x-tmh-signature",
          "timestamp" => "x-tmh-timestamp",
        },
        "key" => "secretUtf8",
        "timestampFormat" => "iso8601",
        "toleranceSeconds" => 300,
      },
      SIGNING,
    )
  end

  def test_the_default_tolerance_is_the_irs
    assert_equal SIGNING["toleranceSeconds"], TeachMeHipaa::Webhook::DEFAULT_TOLERANCE
  end

  def test_generated_headers_are_the_irs
    headers = TeachMeHipaa::Webhook.generate_test_headers(
      payload: WebhookTest::EVENT_BODY, secret: WebhookTest::SECRET, path: WebhookTest::PATH,
      event_type: "learner.certified", event_id: WebhookTest::EVENT_ID, key_id: WebhookTest::KEY_ID
    )

    assert_equal [*SIGNING["headers"].values, "content-type"].sort, headers.keys.sort
  end
end
