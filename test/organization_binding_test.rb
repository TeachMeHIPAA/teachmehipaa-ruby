# frozen_string_literal: true

require_relative "test_helper"

class OrganizationBindingTest < Minitest::Test
  include ClientHelpers

  def test_discovers_the_organization_once_and_reuses_it
    transport = scripted_transport
    client = build_client(transport)

    client.learners.retrieve(LEARNER_ID)
    client.learners.retrieve(LEARNER_ID)

    introspection = only(transport.requests_to("GET", "/auth/introspection"))

    assert_equal "Bearer #{ACCESS_TOKEN}", introspection.headers["authorization"]
    assert_equal(["/v1/organizations/org_acme/learners/#{LEARNER_ID}"] * 2,
                 transport.requests.last(2).map { |r| URI(r.url).path })
  end

  def test_an_explicit_organization_id_skips_discovery
    transport = FakeTransport.new
    transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    transport.on("GET", "/organizations/org_given/learners/#{LEARNER_ID}",
                 FakeTransport::Reply.json(LEARNER_JSON))

    learner = build_client(transport, organization_id: "org_given").learners.retrieve(LEARNER_ID)

    assert_equal LEARNER_ID, learner.learner_id
    assert_empty transport.requests_to("GET", "/auth/introspection")
  end

  def test_concurrent_calls_discover_the_organization_once
    transport = FakeTransport.new
    transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    transport.on("GET", "/auth/introspection", lambda { |_request|
      sleep 0.05 # keep discovery in flight while the other callers arrive
      FakeTransport::Reply.json(introspection_json)
    })
    transport.on("GET", LEARNER_PATH, FakeTransport::Reply.json(LEARNER_JSON))
    client = build_client(transport)

    Array.new(5) { Thread.new { client.learners.retrieve(LEARNER_ID) } }.each(&:join)

    assert_equal 1, transport.requests_to("GET", "/auth/introspection").length
    assert_equal 5, transport.requests_to("GET", LEARNER_PATH).length
  end

  def test_a_token_bound_to_no_organization_raises
    transport = FakeTransport.new
    transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    transport.on("GET", "/auth/introspection", FakeTransport::Reply.json(introspection_json(org_id: nil)))

    error = assert_raises(TeachMeHipaa::Error) { build_client(transport).learners.retrieve(LEARNER_ID) }

    assert_match(/not bound to an Organization/, error.message)
  end
end
