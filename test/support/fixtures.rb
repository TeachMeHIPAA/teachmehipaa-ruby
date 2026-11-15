# frozen_string_literal: true

module Fixtures
  LIVE_BASE = "https://api.tme.so/v1"
  SANDBOX_BASE = "https://api-teachmehipaa-dev.web.app/v1"

  CLIENT_ID = "cli_01JD8Z4N3QX5V7W9Y2B4C6D8EF"
  CLIENT_SECRET = "tmh_cs_k3Jq9-Zx_8LmN2pR4tV6wY0aB1cD3eF5gH7iJ9kL0mN"
  # base64("#{CLIENT_ID}:#{CLIENT_SECRET}"), computed outside the SDK.
  BASIC_CREDENTIALS =
    "Y2xpXzAxSkQ4WjROM1FYNVY3VzlZMkI0QzZEOEVGOnRtaF9jc19rM0pxOS1aeF84TG1OMnBS" \
    "NHRWNndZMGFCMWNEM2VGNWdIN2lKOWtMMG1O"
  ORG_ID = "org_acme"
  LEARNER_ID = "sub_01JD8Z4N3QX5V7W9Y2B4C6D8EG"
  LEARNER_PATH = "/organizations/#{ORG_ID}/learners/#{LEARNER_ID}".freeze
  ACCESS_TOKEN = "eyJhbGciOiJIUzI1NiJ9.first.sig"
  SECOND_ACCESS_TOKEN = "eyJhbGciOiJIUzI1NiJ9.second.sig"
  REQUEST_ID = "req_7f3c2a"
  ETAG = '"9b2f0c4e1d"'

  LEARNER_JSON = {
    "learnerId" => LEARNER_ID,
    "email" => "ana@example.com",
    "name" => "Ana Lima",
    "externalId" => "hr-123",
    "status" => "in_progress",
    "course" => { "courseId" => "hipaa-essentials", "title" => "HIPAA Essentials" },
    "invitedAt" => "2026-11-01T09:00:00Z",
    "startedAt" => "2026-11-02T10:30:00Z",
    "completedAt" => nil,
    "dueAt" => "2026-12-01T00:00:00Z",
    "certificate" => nil,
  }.freeze

  CERTIFICATE_JSON = {
    "certificateId" => "crt_01JD8Z4N3QX5V7W9Y2B4C6D8EH",
    "issuedAt" => "2026-11-10T15:00:00Z",
    "expiresAt" => "2027-11-10T15:00:00Z",
    "verifyUrl" => "https://teachmehipaa.com/verify/crt_01JD8Z4N3QX5V7W9Y2B4C6D8EH",
    "pdfUrl" => "/v1/organizations/org_acme/certificates/crt_01JD8Z4N3QX5V7W9Y2B4C6D8EH/pdf",
  }.freeze

  # Transport failures as Net::HTTP raises them, before any response.
  NETWORK_ERROR = ->(_request) { raise Errno::ECONNREFUSED, "connect(2) for api.tme.so port 443" }
  READ_TIMEOUT = ->(_request) { raise Net::ReadTimeout }

  module_function

  def token_json(access_token = ACCESS_TOKEN, expires_in: 900)
    {
      "access_token" => access_token,
      "token_type" => "Bearer",
      "expires_in" => expires_in,
      "scope" => "learners:read learners:write",
    }
  end

  def introspection_json(org_id: ORG_ID)
    {
      "actorType" => "client",
      "clientId" => CLIENT_ID,
      "subjectId" => nil,
      "orgId" => org_id,
      "scopes" => %w[learners:read learners:write],
      "mode" => "test",
      "expiresAt" => "2026-11-15T12:15:00Z",
    }
  end

  # An RFC 9457 problem reply shaped like the API's problem() helper.
  def problem(status, code, title: "Problem", detail: nil, errors: nil, headers: {})
    body = { "title" => title, "status" => status, "code" => code }
    body["detail"] = detail if detail
    body["errors"] = errors if errors
    FakeTransport::Reply.json(body, status:, content_type: "application/problem+json",
                                    headers: { "x-request-id" => REQUEST_ID }.merge(headers))
  end

  def script_learner_retrieve(transport)
    transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    transport.on("GET", "/auth/introspection", FakeTransport::Reply.json(introspection_json))
    transport.on(
      "GET", LEARNER_PATH,
      FakeTransport::Reply.json(LEARNER_JSON, headers: { "x-request-id" => REQUEST_ID, "etag" => ETAG })
    )
  end
end
