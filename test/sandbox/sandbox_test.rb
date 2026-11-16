# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "teachmehipaa"
require "minitest/autorun"

# Read-only smoke test against the real Sandbox, run by hand with
# `bundle exec rake test:sandbox`. Without credentials every test is
# skipped, and CI never runs it.
class SandboxTest < Minitest::Test
  CLIENT_ID = ENV.fetch("TMH_SANDBOX_CLIENT_ID", "")
  CLIENT_SECRET = ENV.fetch("TMH_SANDBOX_CLIENT_SECRET", "")

  def setup
    skip "set TMH_SANDBOX_CLIENT_ID and TMH_SANDBOX_CLIENT_SECRET" if CLIENT_ID.empty? || CLIENT_SECRET.empty?

    @client = TeachMeHipaa::Client.new(client_id: CLIENT_ID, client_secret: CLIENT_SECRET, environment: :sandbox)
  end

  def test_introspects_a_sandbox_access_token_for_an_organization
    introspection = @client.auth.introspect

    # The spec: "`test` for a Sandbox client, `live` otherwise."
    assert_equal "test", introspection.mode
    assert_kind_of String, introspection.org_id
  end

  def test_lists_courses
    assert_kind_of Array, @client.courses.list(limit: 5).items
  end

  def test_lists_learners
    page = @client.learners.list(limit: 5)

    assert_kind_of Array, page.items
    assert_equal 200, page.last_response.status
  end
end
