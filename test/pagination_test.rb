# frozen_string_literal: true

require_relative "test_helper"

# Auto-paging lists and the Event log tail, through the public client.
class PaginationTest < Minitest::Test
  include ClientHelpers

  LEARNERS_PATH = "/organizations/#{ORG_ID}/learners".freeze
  EVENTS_PATH = "/organizations/#{ORG_ID}/events".freeze

  def setup
    @transport = FakeTransport.new
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    @sleep = FakeSleep.new
    @client = build_client(@transport, organization_id: ORG_ID, sleep: @sleep)
  end

  def test_auto_paging_each_follows_next_cursor_through_a_short_page_until_null
    script(LEARNERS_PATH,
           page([learner("sub_1"), learner("sub_2")], "cur_2"),
           # Filters apply per page, so a page can be short with more to come.
           page([], "cur_3"),
           page([learner("sub_3")], nil))

    learner_ids = []
    @client.learners.list(limit: 2).auto_paging_each { |learner| learner_ids << learner.learner_id }

    assert_equal %w[sub_1 sub_2 sub_3], learner_ids
    assert_equal [{ "limit" => "2" }, { "limit" => "2", "cursor" => "cur_2" }, { "limit" => "2", "cursor" => "cur_3" }],
                 queries(LEARNERS_PATH)
  end

  def test_breaking_out_of_auto_paging_each_stops_fetching_pages
    script(LEARNERS_PATH,
           page([learner("sub_1"), learner("sub_2")], "cur_2"),
           page([learner("sub_3"), learner("sub_4")], "cur_3"),
           page([learner("sub_5")], nil))

    learner_ids = []
    @client.learners.list.auto_paging_each do |learner|
      learner_ids << learner.learner_id
      break if learner.learner_id == "sub_3"
    end

    assert_equal %w[sub_1 sub_2 sub_3], learner_ids
    assert_equal 2, queries(LEARNERS_PATH).length
  end

  def test_every_page_carries_the_first_calls_filters_limit_and_request_options_unvalidated
    script(LEARNERS_PATH, page([learner("sub_1")], "cur_2"), page([learner("sub_2")], nil))

    # 500 is over the API's maximum of 100: the server, not the client,
    # rejects it.
    learners = @client.learners.list(limit: 500, status: "in_progress", course_id: "hipaa-2026",
                                     request_options: { headers: { "x-request-id" => "req_sync_42" } })

    assert_equal %w[sub_1 sub_2], learners.auto_paging_each.map(&:learner_id)
    assert_equal [{ "limit" => "500", "status" => "in_progress", "courseId" => "hipaa-2026" },
                  { "limit" => "500", "status" => "in_progress", "courseId" => "hipaa-2026", "cursor" => "cur_2" }],
                 queries(LEARNERS_PATH)
    assert_equal(%w[req_sync_42 req_sync_42],
                 @transport.requests_to("GET", LEARNERS_PATH).map { |request| request.headers["x-request-id"] })
  end

  def test_the_event_log_pages_by_after_the_last_events_id_not_cursor
    # §4: nextCursor is the last Event id while more rows exist.
    script(EVENTS_PATH, page([event("evt_01"), event("evt_02")], "evt_02"), page([event("evt_03")], nil))

    events = @client.events.list(type: "learner.certified").auto_paging_each.to_a

    assert_equal %w[evt_01 evt_02 evt_03], events.map(&:event_id)
    assert_equal [{ "type" => "learner.certified" }, { "type" => "learner.certified", "after" => "evt_02" }],
                 queries(EVENTS_PATH)
  end

  def test_the_event_log_resumes_after_the_last_event_even_if_next_cursor_differs
    # The IR's after style keys on Event ids, so the last Event handed out is
    # the authoritative position, not the cursor's spelling of it.
    script(EVENTS_PATH, page([event("evt_01"), event("evt_02")], "evt_01"), page([event("evt_03")], nil))

    events = @client.events.list.auto_paging_each.to_a

    assert_equal %w[evt_01 evt_02 evt_03], events.map(&:event_id)
    assert_equal [nil, "evt_02"], after_params
  end

  def test_the_event_log_falls_back_to_next_cursor_after_an_empty_page
    script(EVENTS_PATH, page([], "evt_07"), page([event("evt_08")], nil))

    events = @client.events.list.auto_paging_each.to_a

    assert_equal %w[evt_08], events.map(&:event_id)
    assert_equal [nil, "evt_07"], after_params
  end

  def test_auto_paging_each_without_a_block_is_a_lazy_enumerator
    script(LEARNERS_PATH,
           page([learner("sub_1"), learner("sub_2")], "cur_2"),
           page([learner("sub_3"), learner("sub_4")], "cur_3"),
           page([learner("sub_5")], nil))

    learners = @client.learners.list.auto_paging_each

    assert_kind_of Enumerator, learners
    assert_equal 1, queries(LEARNERS_PATH).length

    assert_equal %w[sub_2 sub_3], learners.lazy.map(&:learner_id).reject { |id| id == "sub_1" }.first(2)
    assert_equal 2, queries(LEARNERS_PATH).length
  end

  def test_a_page_is_enumerable_over_its_own_items_only
    script(LEARNERS_PATH, page([learner("sub_1"), learner("sub_2")], "cur_2"))

    first = @client.learners.list

    assert_equal %w[sub_1 sub_2], first.map(&:learner_id)
    assert_equal 2, first.count
    assert_equal %w[sub_1 sub_2], first.each.map(&:learner_id)
    assert_equal 1, queries(LEARNERS_PATH).length
  end

  def test_a_list_returns_its_first_page_which_fetches_later_pages_on_request
    script(LEARNERS_PATH,
           page([learner("sub_1")], "cur_2", headers: { "x-request-id" => "req_page_1" }),
           page([learner("sub_2")], "cur_3"),
           page([learner("sub_3")], nil))

    first = @client.learners.list(limit: 1)

    assert_equal %w[sub_1], first.items.map(&:learner_id)
    assert_equal "cur_2", first.next_cursor
    assert_equal "req_page_1", first.last_response.request_id
    assert_predicate first, :next_page?
    assert_equal 1, queries(LEARNERS_PATH).length

    second = first.next_page

    assert_equal %w[sub_2], second.items.map(&:learner_id)
    assert_equal([%w[sub_2], %w[sub_3]], second.each_page.map { |p| p.items.map(&:learner_id) })
    assert_equal 3, queries(LEARNERS_PATH).length
  end

  def test_each_page_yields_this_page_then_each_later_page
    script(LEARNERS_PATH, page([learner("sub_1")], "cur_2"), page([], "cur_3"), page([learner("sub_2")], nil))

    pages = []
    @client.learners.list.each_page { |p| pages << p.items.map(&:learner_id) }

    assert_equal [%w[sub_1], [], %w[sub_2]], pages
  end

  def test_next_page_on_the_last_page_raises_without_a_request
    script(LEARNERS_PATH, page([learner("sub_1")], nil))

    last = @client.learners.list

    refute_predicate last, :next_page?
    error = assert_raises(StopIteration) { last.next_page }
    assert_match(/last page/, error.message)
    assert_equal 1, queries(LEARNERS_PATH).length
  end

  def test_tail_resumes_from_an_event_id_and_returns_once_caught_up
    script(EVENTS_PATH,
           page([event("evt_03"), event("evt_04")], "evt_04"),
           # §4: nextCursor is null at the current end, so it gives no resume
           # point; the tail keeps the last id itself.
           page([event("evt_05")], nil))

    tail = @client.events.tail(after: "evt_02", type: "learner.certified", limit: 2)

    assert_equal "evt_02", tail.last_event_id
    assert_equal %w[evt_03 evt_04 evt_05], tail.map(&:event_id)
    assert_equal "evt_05", tail.last_event_id
    assert_equal [{ "limit" => "2", "after" => "evt_02", "type" => "learner.certified" },
                  { "limit" => "2", "after" => "evt_04", "type" => "learner.certified" }],
                 queries(EVENTS_PATH)
    assert_empty @sleep.waits
  end

  def test_tail_without_an_id_starts_at_the_oldest_retained_event
    script(EVENTS_PATH, page([event("evt_01")], nil))

    tail = @client.events.tail

    assert_nil tail.last_event_id
    assert_equal %w[evt_01], tail.map(&:event_id)
    assert_equal [nil], after_params
    assert_equal "evt_01", tail.last_event_id
  end

  def test_iterating_a_tail_again_resumes_from_its_last_event_id
    script(EVENTS_PATH, page([event("evt_03")], nil), page([event("evt_04")], nil))

    tail = @client.events.tail(after: "evt_02")

    assert_equal %w[evt_03], tail.map(&:event_id)
    assert_equal %w[evt_04], tail.map(&:event_id)
    assert_equal %w[evt_02 evt_03], after_params
  end

  def test_following_tail_polls_from_its_last_id_every_2_seconds_until_stopped
    script(EVENTS_PATH,
           page([event("evt_03")], nil),
           page([], nil),
           page([event("evt_04"), event("evt_05")], nil))
    stopping = false

    tail = @client.events.tail(after: "evt_02", follow: true, stop: -> { stopping })
    event_ids = []
    tail.each do |event|
      event_ids << event.event_id
      stopping = true if event.event_id == "evt_04"
    end

    # The stop lands mid-page: evt_05 was fetched but never handed out, so a
    # resume from last_event_id picks it up.
    assert_equal %w[evt_03 evt_04], event_ids
    assert_equal "evt_04", tail.last_event_id
    assert_equal %w[evt_02 evt_03 evt_03], after_params
    assert_equal [2.0, 2.0], @sleep.waits
  end

  def test_following_tail_waits_the_interval_and_stops_polling_on_break
    script(EVENTS_PATH, page([], nil), page([event("evt_03")], nil))

    tail = @client.events.tail(after: "evt_02", follow: true, interval: 0.25)
    seen = []
    tail.each do |event|
      seen << event.event_id
      break if event.event_id == "evt_03"
    end

    assert_equal %w[evt_03], seen
    assert_equal %w[evt_02 evt_02], after_params
    assert_equal [0.25], @sleep.waits
    assert_equal "evt_03", tail.last_event_id
  end

  def test_a_stop_that_is_already_set_ends_the_tail_without_a_request
    tail = @client.events.tail(after: "evt_02", follow: true, stop: -> { true })

    assert_empty tail.to_a
    assert_empty queries(EVENTS_PATH)
    assert_equal "evt_02", tail.last_event_id
  end

  def test_tail_each_without_a_block_is_a_lazy_enumerator
    script(EVENTS_PATH, page([event("evt_03"), event("evt_04")], "evt_04"), page([event("evt_05")], nil))

    events = @client.events.tail(after: "evt_02").each

    assert_kind_of Enumerator, events
    assert_empty queries(EVENTS_PATH)
    assert_equal %w[evt_03], events.first(1).map(&:event_id)
    assert_equal 1, queries(EVENTS_PATH).length
  end

  private

  def learner(learner_id)
    LEARNER_JSON.merge("learnerId" => learner_id)
  end

  # dev#/components/schemas/Event, a learner.certified envelope.
  def event(event_id)
    {
      "eventId" => event_id,
      "eventType" => "learner.certified",
      "orgId" => ORG_ID,
      "occurredAt" => "2026-11-15T16:31:30.000Z",
      "data" => {
        "learnerId" => LEARNER_ID,
        "email" => "ana@example.com",
        "externalId" => "hr-123",
        "courseId" => "hipaa-2026",
        "status" => "certified",
        "occurredAt" => "2026-11-15T16:31:30.000Z",
      },
    }
  end

  # research api-sdk-surface.md §4: { items, nextCursor }.
  def page(items, next_cursor, headers: {})
    FakeTransport::Reply.json({ "items" => items, "nextCursor" => next_cursor }, headers:)
  end

  def script(path, *pages)
    pages.each { |reply| @transport.on("GET", path, reply) }
  end

  def queries(path)
    @transport.requests_to("GET", path).map { |request| URI.decode_www_form(URI(request.url).query.to_s).to_h }
  end

  def after_params
    queries(EVENTS_PATH).map { |query| query["after"] }
  end
end
