# frozen_string_literal: true

require_relative "test_helper"

# The catalog and Certificate verification need no Access token (spec story
# 27), so they send none, and work on a client built without credentials.
class PublicEndpointsTest < Minitest::Test
  include ClientHelpers

  COURSE_ID = "hipaa-essentials"
  TINY_ID = "x7Kq2p"
  # dev#/components/schemas/CourseDto
  COURSE_JSON = {
    "courseId" => COURSE_ID, "title" => "HIPAA Essentials", "courseVersion" => "2026.1", "passingThreshold" => 0.8
  }.freeze
  # dev#/components/schemas/CertificateVerificationDto
  VERIFICATION_JSON = {
    "status" => "valid", "learnerName" => "Ana Lima", "courseTitle" => "HIPAA Essentials",
    "issuedAt" => "2026-11-10T15:00:00Z", "expiresAt" => "2027-11-10T15:00:00Z", "issuer" => "TeachMeHIPAA"
  }.freeze
  NO_CREDENTIALS = /no credentials; pass client_id and client_secret, or token_provider/

  def setup
    @transport = FakeTransport.new
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    @transport.on("GET", "/courses", FakeTransport::Reply.json({ "items" => [COURSE_JSON], "nextCursor" => nil }))
    @transport.on("GET", "/courses/#{COURSE_ID}", FakeTransport::Reply.json(COURSE_JSON))
    @transport.on("GET", "/certificate-verifications/#{TINY_ID}", FakeTransport::Reply.json(VERIFICATION_JSON))
  end

  def test_public_methods_send_no_access_token_even_on_a_client_with_credentials
    client = build_client(@transport)

    call_every_public_method(client)

    assert_empty @transport.requests_to("POST", "/auth/token")
    assert_equal([nil] * 3, @transport.requests.map { |r| r.headers["authorization"] })
  end

  def test_a_client_without_credentials_calls_the_public_methods
    client = TeachMeHipaa::Client.new(environment: :sandbox, transport: FakeTransport.new(SANDBOX_BASE).tap do |t|
      t.on("GET", "/courses/#{COURSE_ID}", FakeTransport::Reply.json(COURSE_JSON))
    end)

    assert_equal "HIPAA Essentials", client.courses.retrieve(COURSE_ID).title
  end

  def test_a_client_without_credentials_refuses_an_authenticated_call_before_sending
    client = TeachMeHipaa::Client.new(transport: @transport)

    error = assert_raises(TeachMeHipaa::AuthenticationError) { client.learners.retrieve(LEARNER_ID) }

    assert_match NO_CREDENTIALS, error.message
    assert_empty @transport.requests
  end

  def test_a_client_without_credentials_refuses_before_sending_even_when_bound_to_an_organization
    client = TeachMeHipaa::Client.new(organization_id: ORG_ID, transport: @transport)

    error = assert_raises(TeachMeHipaa::AuthenticationError) { client.learners.retrieve(LEARNER_ID) }

    assert_match NO_CREDENTIALS, error.message
    assert_empty @transport.requests
  end

  def test_partial_credentials_still_raise_at_construction
    [{ client_id: CLIENT_ID }, { client_secret: CLIENT_SECRET }, { scopes: ["learners:read"] }].each do |partial|
      error = assert_raises(ArgumentError, partial.inspect) { TeachMeHipaa::Client.new(**partial) }

      assert_match(/client_id and client_secret/, error.message)
    end
  end

  private

  def call_every_public_method(client)
    client.courses.list
    client.courses.retrieve(COURSE_ID)
    client.certificate_verifications.retrieve(TINY_ID)
  end
end
