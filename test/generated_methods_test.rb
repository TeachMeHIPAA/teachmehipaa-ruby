# frozen_string_literal: true

require_relative "test_helper"

class GeneratedMethodsTest < Minitest::Test
  include ClientHelpers

  UUID_V4 = /\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z/
  ENROLLMENT_ID = "enr_01JD8C"
  SUBSCRIPTION_ID = "whs_01JD8D"
  PARTNER_ID = "ptn_01JD8E"
  CERTIFICATE_ID = "cert_01JD8F"
  ORG = "/organizations/#{Fixtures::ORG_ID}".freeze

  # dev#/components/schemas/EnrollmentDto
  ENROLLMENT_JSON = {
    "enrollmentId" => ENROLLMENT_ID, "subjectId" => Fixtures::LEARNER_ID, "courseId" => "hipaa-2026",
    "orgId" => Fixtures::ORG_ID, "status" => "CANCELLED", "effectiveStatus" => "CANCELLED", "archived" => false,
    "cycle" => 0, "rev" => 3, "invitedAt" => "2026-11-01T09:00:00.000Z", "startedAt" => nil,
    "completedAt" => nil, "certifiedAt" => nil, "expiresAt" => nil, "certificateId" => nil
  }.freeze

  # dev#/components/schemas/WebhookSubscriptionDto
  SUBSCRIPTION_JSON = {
    "subscriptionId" => SUBSCRIPTION_ID, "endpointUrl" => "https://hr.example.com/hooks/tmh",
    "eventTypes" => ["learner.certified"], "enabled" => false, "description" => nil, "seatsLowThreshold" => 5,
    "secretKeyId" => "whk_01JD8G", "createdAt" => "2026-11-10T08:00:00.000Z", "rev" => 2
  }.freeze

  def setup
    @transport = FakeTransport.new
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    @client = build_client(@transport, organization_id: ORG_ID)
  end

  def test_a_custom_method_posts_to_its_colon_path_with_a_generated_idempotency_key
    path = "#{ORG}/enrollments/#{ENROLLMENT_ID}:cancel"
    @transport.on("POST", path, FakeTransport::Reply.json(ENROLLMENT_JSON))

    enrollment = @client.enrollments.cancel(ENROLLMENT_ID, refund: false)

    assert_instance_of TeachMeHipaa::Enrollment, enrollment
    assert_kind_of TeachMeHipaa::CancelEnrollmentResponse, enrollment
    assert_equal [ENROLLMENT_ID, TeachMeHipaa::EnrollmentStatus::CANCELLED],
                 [enrollment.enrollment_id, enrollment.status]
    request = only(@transport.requests_to("POST", path))

    assert_match UUID_V4, request.headers["idempotency-key"]
    assert_equal "application/json", request.headers["content-type"]
    assert_equal({ "refund" => false }, JSON.parse(request.body))
  end

  def test_a_refunded_cancel_reads_as_the_refunded_variant
    path = "#{ORG}/enrollments/#{ENROLLMENT_ID}:cancel"
    refunded = ENROLLMENT_JSON.merge("refund" => { "refundId" => "re_1", "status" => "succeeded" })
    @transport.on("POST", path, FakeTransport::Reply.json(refunded))

    assert_instance_of TeachMeHipaa::EnrollmentCancelRefunded, @client.enrollments.cancel(ENROLLMENT_ID, refund: true)
  end

  def test_a_partner_method_takes_the_partner_id_and_skips_the_organization_lookup
    path = "/partners/#{PARTNER_ID}/organizations"
    items = [{ "orgId" => "org_clinic", "name" => "Clinic", "createdAt" => "2026-11-02T10:00:00.000Z",
               "grantActive" => true }]
    @transport.on("GET", path, FakeTransport::Reply.json({ "items" => items, "nextCursor" => "cur_2" },
                                                         headers: { "x-request-id" => "req_page" }))

    page = build_client(@transport).partners.organizations.list(PARTNER_ID, limit: 10)

    assert_instance_of TeachMeHipaa::Page, page
    assert_equal ["org_clinic"], page.items.map(&:org_id)
    assert_equal Time.utc(2026, 11, 2, 10), page.items.first.created_at
    assert_equal "cur_2", page.next_cursor
    assert_equal "req_page", page.last_response.request_id
    assert_equal ["#{LIVE_BASE}/auth/token", "#{LIVE_BASE}#{path}?limit=10"], @transport.requests.map(&:url)
  end

  def test_a_patch_sends_a_merge_patch_keeping_an_explicit_nil
    path = "#{ORG}/webhook-subscriptions/#{SUBSCRIPTION_ID}"
    @transport.on("PATCH", path, FakeTransport::Reply.json(SUBSCRIPTION_JSON))

    subscription = @client.webhook_subscriptions.update(SUBSCRIPTION_ID, if_match: ETAG, enabled: false,
                                                                         description: nil)

    refute subscription.enabled
    request = only(@transport.requests_to("PATCH", path))

    assert_equal "application/merge-patch+json", request.headers["content-type"]
    assert_equal ETAG, request.headers["if-match"]
    refute request.headers.key?("idempotency-key")
    assert_equal '{"enabled":false,"description":null}', request.body
  end

  def test_a_204_delete_returns_its_response_metadata
    path = "#{ORG}/webhook-subscriptions/#{SUBSCRIPTION_ID}"
    @transport.on("DELETE", path, FakeTransport::Reply.empty(headers: { "x-request-id" => "req_deleted" }))

    deleted = @client.webhook_subscriptions.delete(SUBSCRIPTION_ID)

    assert_instance_of TeachMeHipaa::EmptyResponse, deleted
    assert_equal [204, "req_deleted"], [deleted.last_response.status, deleted.last_response.request_id]
    request = only(@transport.requests_to("DELETE", path))

    assert_nil request.body
    refute request.headers.key?("content-type")
  end

  def test_a_learner_upsert_answered_201_was_created_with_its_delivery_details
    path = "#{ORG}/learners/by-external-id/hr%20123%2Fa"
    created = LEARNER_JSON.merge("delivery" => "none", "joinUrl" => "https://tme.so/j/abc")
    @transport.on("PUT", path, FakeTransport::Reply.json(created, status: 201))

    result = @client.learners.upsert_by_external_id("hr 123/a", email: "ana@example.com")

    assert_instance_of TeachMeHipaa::LearnerWriteResult, result
    assert_predicate result, :created?
    assert_equal ["none", "https://tme.so/j/abc"], [result.delivery, result.join_url]
    assert_equal 201, result.last_response.status
    request = only(@transport.requests_to("PUT", path))

    assert_match UUID_V4, request.headers["idempotency-key"]
    assert_equal({ "email" => "ana@example.com" }, JSON.parse(request.body))
  end

  def test_a_learner_upsert_answered_200_found_an_existing_learner
    @transport.on("PUT", "#{ORG}/learners/by-external-id/hr-123", FakeTransport::Reply.json(LEARNER_JSON))

    result = @client.learners.upsert_by_external_id("hr-123", email: "ana@example.com", name: "Ana Lima")

    refute_predicate result, :created?
    assert_nil result.join_url
    assert_equal LEARNER_ID, result.learner_id
  end

  def test_keeps_unknown_fields_and_accepts_unknown_enum_values
    path = "#{ORG}/enrollments/#{ENROLLMENT_ID}"
    future = ENROLLMENT_JSON.merge("effectiveStatus" => "ON_HOLD", "holdReason" => "leave")
    @transport.on("GET", path, FakeTransport::Reply.json(future))

    enrollment = @client.enrollments.retrieve(ENROLLMENT_ID)

    assert_equal "ON_HOLD", enrollment.effective_status
    assert_equal "leave", enrollment["holdReason"]
    assert_equal "leave", enrollment.to_h[:holdReason]
  end

  def test_an_unknown_union_variant_reads_as_the_generic_variant_and_keeps_its_fields
    path = "#{ORG}/audit-events"
    issued = { "eventId" => "aud_1", "at" => "2026-11-14T09:00:00Z", "type" => "certificate.issued",
               "actorSubjectId" => "sub_admin", "actor" => { "type" => "user", "subjectId" => "sub_admin" },
               "certificateId" => CERTIFICATE_ID, "subjectId" => LEARNER_ID, "courseId" => "hipaa-2026" }
    teleported = { "eventId" => "aud_2", "at" => "2026-11-14T10:00:00Z", "type" => "learner.teleported",
                   "actor" => { "type" => "robot", "robotId" => "r2" }, "destination" => "Mars" }
    @transport.on("GET", path, FakeTransport::Reply.json({ "items" => [issued, teleported], "nextCursor" => nil }))

    known, unknown = @client.audit_events.list(type: "certificate.issued").items

    assert_instance_of TeachMeHipaa::AuditEventCertificateIssued, known
    assert_instance_of TeachMeHipaa::AuditEventActorUser, known.actor
    assert_instance_of TeachMeHipaa::AuditEvent::Unknown, unknown
    assert_kind_of TeachMeHipaa::AuditEvent, unknown
    assert_equal %w[learner.teleported Mars robot], [unknown[:type], unknown["destination"], unknown["actor"]["type"]]
  end

  def test_a_date_time_query_parameter_is_sent_as_an_iso_date_time
    path = "#{ORG}/audit-events"
    @transport.on("GET", path, FakeTransport::Reply.json({ "items" => [], "nextCursor" => nil }))

    @client.audit_events.list(since: Time.utc(2026, 11, 1), until: Time.utc(2026, 11, 15, 12, 30))

    query = URI.decode_www_form(URI(only(@transport.requests_to("GET", path)).url).query).to_h

    assert_equal({ "since" => "2026-11-01T00:00:00Z", "until" => "2026-11-15T12:30:00Z" }, query)
  end
end
