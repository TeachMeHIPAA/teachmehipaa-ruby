# frozen_string_literal: true

require_relative "test_helper"

class ClientConfigTest < Minitest::Test
  include ClientHelpers

  def test_defaults_to_the_live_environment
    transport = scripted_transport
    client = build_client(transport)

    client.learners.retrieve(LEARNER_ID)

    assert_equal :live, client.environment
    assert_equal "https://api.tme.so/v1", client.base_url
    assert_equal ["api.tme.so"], hosts_called(transport)
  end

  def test_sandbox_environment_calls_the_sandbox_deployment
    transport = scripted_transport(SANDBOX_BASE)
    client = build_client(transport, environment: :sandbox)

    client.learners.retrieve(LEARNER_ID)

    assert_equal "https://sandbox.api.tme.so/v1", client.base_url
    assert_equal ["sandbox.api.tme.so"], hosts_called(transport)
    assert_equal "https://sandbox.api.tme.so/v1/auth/token", transport.requests.first.url
  end

  def test_base_url_overrides_the_environment
    transport = scripted_transport("http://localhost:4010")
    client = build_client(transport, environment: :sandbox, base_url: "http://localhost:4010/")

    client.learners.retrieve(LEARNER_ID)

    assert_equal ["localhost"], hosts_called(transport)
    assert_equal "http://localhost:4010/auth/token", transport.requests.first.url
  end

  def test_rejects_an_unknown_environment
    error = assert_raises(ArgumentError) { build_client(FakeTransport.new, environment: "staging") }

    assert_match(/environment/, error.message)
  end

  def test_rejects_a_negative_retry_count
    assert_raises(ArgumentError) { build_client(FakeTransport.new, max_retries: -1) }
  end

  def test_exposes_retry_and_timeout_settings
    client = build_client(FakeTransport.new)
    tuned = build_client(FakeTransport.new, max_retries: 5, timeout: 12.5)

    assert_equal 2, client.max_retries
    assert_in_delta 80.0, client.timeout
    assert_equal 5, tuned.max_retries
    assert_in_delta 12.5, tuned.timeout
  end

  def test_sends_each_request_with_the_client_timeout
    transport = scripted_transport
    build_client(transport, timeout: 12.5).learners.retrieve(LEARNER_ID)

    assert_equal [12.5] * 3, transport.requests.map(&:timeout)
  end

  def test_configuration_cannot_be_changed_after_construction
    client = build_client(FakeTransport.new)

    assert_predicate client, :frozen?
    assert_predicate client.config, :frozen?
    refute_respond_to client, :base_url=
    refute_respond_to client.config, :base_url=
    assert_raises(FrozenError) { client.instance_variable_set(:@config, nil) }
  end

  def test_identifies_the_sdk_and_app_in_the_user_agent
    transport = scripted_transport
    client = build_client(transport, app_info: { name: "AcmeHR", version: "4.2", url: "https://acme.example" })

    client.learners.retrieve(LEARNER_ID)

    expected = %r{\Ateachmehipaa-ruby/#{Regexp.escape(TeachMeHipaa::VERSION)} ruby/\S+ AcmeHR/4\.2 \(https://acme\.example\)\z}

    transport.requests.each { |request| assert_match expected, request.headers["user-agent"] }
  end

  def test_inspecting_the_client_never_reveals_the_secret
    client = build_client(scripted_transport)
    client.learners.retrieve(LEARNER_ID)

    [client, client.learners, client.config].each do |object|
      refute_includes object.inspect, CLIENT_SECRET
      refute_includes object.inspect, ACCESS_TOKEN
    end
  end

  def test_logs_each_exchange_without_bodies_or_credentials
    transport = scripted_transport
    logger = RecordingLogger.new

    build_client(transport, logger:, clock: FakeClock.new).learners.retrieve(LEARNER_ID, course_id: "hipaa-advanced")

    assert_equal 3, logger.lines.length
    assert_equal "teachmehipaa.request method=GET path=/v1/organizations/org_acme/learners/#{LEARNER_ID} " \
                 "status=200 elapsed_ms=0 request_id=#{REQUEST_ID}",
                 logger.lines.last
    logger.lines.each do |line|
      [CLIENT_SECRET, BASIC_CREDENTIALS, ACCESS_TOKEN, "ana@example.com", "hipaa-advanced"].each do |secret|
        refute_includes line, secret
      end
    end
  end

  private

  def hosts_called(transport)
    transport.requests.map { |r| URI(r.url).host }.uniq
  end
end
