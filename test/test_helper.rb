# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "teachmehipaa"
require "minitest/autorun"

require_relative "support/fixtures"
require_relative "support/fake_transport"

module ClientHelpers
  include Fixtures

  def scripted_transport(base_url = LIVE_BASE)
    FakeTransport.new(base_url).tap { |t| script_learner_retrieve(t) }
  end

  def build_client(transport, **)
    TeachMeHipaa::Client.new(client_id: CLIENT_ID, client_secret: CLIENT_SECRET, transport:, **)
  end

  def only(items)
    assert_equal 1, items.length, "expected exactly one, got #{items.length}"
    items.first
  end
end
