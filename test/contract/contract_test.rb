# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "teachmehipaa"
require "minitest/autorun"
require_relative "prism"

# The public client against a Prism mock of the vendored developer spec: one
# representative call per resource family. A request that breaks the spec
# fails the call (Prism answers 4xx) or the test (a violation in
# sl-violations).
class ContractTest < Minitest::Test
  # Values that satisfy the spec's path-parameter patterns.
  ORG_ID = "org_acme"
  LEARNER_ID = "sub_01JD80AB2C3D4E5F6G7H8J9K0M"
  ENROLLMENT_ID = "sub_01JD80AB2C3D4E5F6G7H8J9K0M__hipaa-2026"
  CERTIFICATE_ID = "cert_01JD8F"
  COURSE_ID = "hipaa-2026"
  SUBSCRIPTION_ID = "whs_01JD8D"
  OPERATION_ID = "op-01JD8H"
  PARTNER_ID = "ptn_01JD8E2C3D4E5F6G7H8J9K0M1N"
  TINY_ID = "cAbCdEfGhIjKl"

  def setup
    @violations = Prism::Violations.new
    # Prism can't mint tokens from the form-encoded /auth/token, so the
    # client sends a static one and skips Organization discovery.
    @client = TeachMeHipaa::Client.new(
      token_provider: TeachMeHipaa::TokenProviders::Static.new("contract-test-token"),
      organization_id: ORG_ID,
      base_url: Prism.base_url,
      max_retries: 0,
      transport: @violations,
    )
  end

  # Checked after every test, so no test can forget it; Minitest reports a
  # teardown failure against the test.
  def teardown
    assert_empty @violations.found, "Prism reported request violations" # rubocop:disable Minitest/AssertionInLifecycleHook
  end

  def test_the_harness_catches_a_request_that_breaks_the_spec
    assert_raises(TeachMeHipaa::InvalidRequestError) { @client.seat_orders.quote(quantity: 0) }

    assert_equal 1, @violations.found.length
    assert_includes @violations.found.first, "quantity"
    @violations.found.clear
  end

  def test_lists_courses_as_a_page
    page = @client.courses.list(limit: 5)

    assert_kind_of TeachMeHipaa::Page, page
    page.each do |course|
      assert_kind_of String, course.course_id
      assert_kind_of Numeric, course.passing_threshold
    end
    assert_equal 200, page.last_response.status
  end

  def test_retrieves_a_course
    assert_kind_of String, @client.courses.retrieve(COURSE_ID).title
  end

  def test_retrieves_a_certificate_verification
    verification = @client.certificate_verifications.retrieve(TINY_ID)

    assert_kind_of String, verification.learner_name
    assert_kind_of String, verification.issuer
  end

  def test_creates_a_learner_and_reports_whether_it_was_created
    result = @client.learners.create(email: "ana@example.com", name: "Ana Example", external_id: "hr-123",
                                     course_id: COURSE_ID, delivery: "none")

    assert_kind_of String, result.learner_id
    assert_includes [true, false], result.created
  end

  def test_lists_learners_with_filters
    page = @client.learners.list(limit: 10, status: "in_progress", email: "ana@example.com")

    page.each { |learner| assert_kind_of String, learner.email }
    assert_equal 200, page.last_response.status
  end

  def test_retrieves_a_learner
    learner = @client.learners.retrieve(LEARNER_ID, course_id: COURSE_ID)

    assert_kind_of String, learner.learner_id
    assert_kind_of String, learner.course.course_id
  end

  def test_updates_a_learner_as_a_merge_patch_with_if_match
    learner = @client.learners.update(LEARNER_ID, if_match: '"7"', name: "Ana Q. Example", external_id: nil)

    assert_kind_of String, learner.learner_id
  end

  def test_cancels_an_enrollment
    result = @client.enrollments.cancel(ENROLLMENT_ID, refund: false)

    assert_equal 200, result.last_response.status
  end

  def test_retrieves_a_certificate
    assert_kind_of String, @client.certificates.retrieve(CERTIFICATE_ID).certificate_id
  end

  def test_downloads_a_certificate_pdf
    pdf = @client.certificates.download_pdf(CERTIFICATE_ID)

    assert_kind_of String, pdf.data
    assert pdf_type?(pdf.content_type), "got #{pdf.content_type}"
  end

  def test_streams_a_certificate_pdf_to_a_block
    chunks = []
    streamed = @client.certificates.download_pdf(CERTIFICATE_ID) { |chunk| chunks << chunk }

    assert_kind_of TeachMeHipaa::StreamedResponse, streamed
    assert pdf_type?(streamed.content_type), "got #{streamed.content_type}"
  end

  def test_quotes_a_seat_order
    assert_kind_of Integer, @client.seat_orders.quote(quantity: 10, currency: "usd").quantity
  end

  def test_creates_a_webhook_subscription_with_its_signing_secret
    subscription = @client.webhook_subscriptions.create(
      endpoint_url: "https://hr.example.com/hooks/tmh", event_types: %w[learner.certified seats.low],
      description: "HR sync", seats_low_threshold: 5
    )

    assert_kind_of String, subscription.subscription_id
    assert_kind_of String, subscription.secret
  end

  def test_deletes_a_webhook_subscription
    result = @client.webhook_subscriptions.delete(SUBSCRIPTION_ID)

    assert_equal 204, result.last_response.status
  end

  def test_lists_the_event_log
    page = @client.events.list(limit: 25)

    page.each { |event| assert_kind_of String, event.event_type }
    assert_equal 200, page.last_response.status
  end

  def test_retrieves_an_operation_that_can_be_waited_on
    operation = @client.operations.retrieve(OPERATION_ID)

    assert_kind_of TeachMeHipaa::Operation, operation
    assert_kind_of String, operation.name
  end

  def test_introspects_the_access_token
    assert_kind_of String, @client.auth.introspect.actor_type
  end

  def test_lists_a_partners_organizations
    page = @client.partners.organizations.list(PARTNER_ID, limit: 10)

    page.each { |organization| assert_kind_of String, organization.org_id }
    assert_equal 200, page.last_response.status
  end

  private

  def pdf_type?(content_type)
    content_type.to_s.start_with?("application/pdf")
  end
end
