# Pagination and events

List methods return one page at a time; the client can walk every page for
you. The Event log is a list too, with a helper that follows it as new Events
arrive.

## Pages

A list method returns a `TeachMeHipaa::Page` with `items` and `next_cursor`.
Like Stripe's list objects, a page is `Enumerable` over its own items only.
`auto_paging_each` yields every item across all pages, fetching the next page
only when the loop reaches it, and stops fetching when you `break`. Without a
block it returns an `Enumerator`, so `lazy` and `first(n)` fetch only the
pages they need:

<!-- sample: pagination -->
```ruby
# Every Learner, page by page, fetched lazily.
client.learners.list(limit: 100).auto_paging_each do |learner|
  puts learner.learner_id
end

# The first ten certified Learners, fetching no more pages than that takes.
certified = client.learners.list.auto_paging_each.lazy.select(&:certificate).first(10)
puts certified.length

# One page at a time.
page = client.enrollments.list(limit: 50)
puts page.items.length
while page.next_page?
  page = page.next_page
  puts page.items.length
end
```

`limit:` sets the page size (1 to 100, 20 by default). Later pages repeat the
first call's filters, limit and request options. `each_page` yields each page
in turn, which suits batch work and progress reporting:

<!-- sample: each-page -->
```ruby
client.certificates.list(limit: 100).each_page do |page|
  puts "Page of #{page.items.length} (request #{page.last_response.request_id})"
end
```

A page is frozen, so it is safe to hand to another thread.

## The Event log

Each Organization keeps an Event log of what happened in it, such as a
Learner being certified, for 30 days. `events.list` reads it, oldest first,
and takes `type:` to read one Event type:

<!-- sample: events-list -->
```ruby
client.events.list(type: "learner.certified").auto_paging_each do |event|
  puts "#{event.occurred_at.iso8601} #{event.data.email}"
end
```

Reading the Event log needs the `webhooks:manage` or the `audit:read` Scope.
The same Events arrive as webhook Deliveries; see [Webhooks](webhooks.md).

## Event types

Events are typed by `event_type`: a `learner.certified` Event is a
`TeachMeHipaa::EventLearnerCertified`, and so on. Event types are added over
time, and an Event of a type this version doesn't know arrives as a
`TeachMeHipaa::UnknownEvent`, whose fields you can still read with `[]`. So
`case` on the class, and always keep an `else`:

<!-- sample: event-types -->
```ruby
client.events.list.auto_paging_each do |event|
  case event
  when TeachMeHipaa::EventLearnerCertified
    puts "#{event.data.email} is certified"
  when TeachMeHipaa::EventLearnerExpiring
    puts "#{event.data.email} needs to renew"
  else
    puts "skipped #{event.event_type}"
  end
end
```

The Event types are `learner.invited`, `learner.started`,
`learner.certified`, `learner.expiring`, `learner.expired`,
`learner.removed`, `invite.bounced`, `enrollment.certified`,
`certificate.revoked`, `seat.consumed`, `seat.freed` and `seats.low`.
`TeachMeHipaa::EventType` holds them as constants.

## Tailing the Event log

`events.tail` reads the Event log from a position you saved and keeps its own
position in `last_event_id`. Save it as you go, and resume from it after a
restart to catch up on anything that happened while you were down, without
running a webhook endpoint. Here `cursor_store` stands in for your own
storage and `shutting_down?` for your service's stop signal:

<!-- sample: events-tail -->
```ruby
tail = client.events.tail(after: cursor_store.load, follow: true, interval: 5, stop: -> { shutting_down? })
tail.each do |event|
  puts "#{event.event_type} #{event.event_id}"
  cursor_store.save(tail.last_event_id)
end
```

- `after:` is an Event id (exclusive). `nil` starts at the oldest Event the
  log still holds.
- Without `follow:`, the loop ends once it has caught up. With
  `follow: true`, the tail polls every `interval` seconds (2 by default) until
  you `break` or `stop` returns true.
- `type:` and `limit:` apply to every request.
- A tail keeps a position, so use each one from one thread at a time.

Since the log keeps Events for 30 days, a tail that was down longer than
that misses the oldest ones.
