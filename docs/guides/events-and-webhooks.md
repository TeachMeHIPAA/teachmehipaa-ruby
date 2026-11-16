# Events and webhooks

When something happens in an Organization, such as a Learner finishing
training, TeachMeHIPAA records an Event. You can hear about Events
two ways: pull them from the Event log, or let a Webhook subscription push
them to your app. The samples assume a `client` built as in the
[README](../../README.md#usage).

## The Event log

`events.list` reads the last 30 days of Events, oldest first. `type:` narrows
it to one Event type:

<!-- sample: events-list -->
```ruby
client.events.list(type: "learner.certified").auto_paging_each do |event|
  puts "#{event.occurred_at.iso8601} #{event.data.email}"
end
```

Reading the log takes the `webhooks:manage` or the `audit:read` Scope.

## Event classes

Each Event type has its own class: a `learner.certified` Event is a
`TeachMeHipaa::EventLearnerCertified`, and its `data` has typed readers. New
types appear over time, and one this version of the gem doesn't know yet
arrives as a `TeachMeHipaa::UnknownEvent`, whose fields `[]` still reads. So
a `case` on the class wants an `else`:

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

Today's types are `learner.invited`, `learner.started`, `learner.certified`,
`learner.expiring`, `learner.expired`, `learner.removed`, `invite.bounced`,
`enrollment.certified`, `certificate.revoked`, `seat.consumed`, `seat.freed`
and `seats.low`. `TeachMeHipaa::EventType` has a constant for each.

## Following the log

`events.tail` turns the log into a feed you can resume. It remembers the last
Event it handed you in `last_event_id`; save that as you go and pass it back
as `after:` after a restart. A worker built this way catches up on what it
missed and needs no public endpoint. Below, `cursor_store` stands in for your
storage and `shutting_down?` for your stop signal:

<!-- sample: events-tail -->
```ruby
tail = client.events.tail(after: cursor_store.load, follow: true, interval: 5, stop: -> { shutting_down? })
tail.each do |event|
  puts "#{event.event_type} #{event.event_id}"
  cursor_store.save(tail.last_event_id)
end
```

- `after:` is an Event id, and the tail starts after it. `nil` starts at
  the oldest Event the log still holds.
- Without `follow:` the loop ends once it catches up. With `follow: true` it
  polls every `interval` seconds (2 by default) until you `break` or `stop`
  returns true.
- `type:` and `limit:` apply to every request the tail makes.
- A tail keeps a position, so give each one to a single thread.

The log forgets Events after 30 days. A worker that stays down longer than
that misses the oldest ones.

## Webhook subscriptions

A Webhook subscription tells TeachMeHIPAA to POST the Event types you pick to
your URL as they happen. Each POST is a Delivery, signed with the
subscription's Signing secret. Managing subscriptions takes the
`webhooks:manage` Scope.

<!-- sample: create-subscription -->
```ruby
subscription = client.webhook_subscriptions.create(
  endpoint_url: "https://hr.example.com/webhooks/tmh",
  event_types: %w[learner.certified learner.expiring],
  description: "HR system",
)
puts subscription.subscription_id
puts subscription.secret
```

Save `secret` somewhere your endpoint can read it. The API shows it this
once. `webhook_subscriptions.update` needs `if_match:` (see
[ETags](models-and-pages.md#etags)), and `delete` removes the subscription.

## Verifying a Delivery

`TeachMeHipaa::Webhook.construct_event` checks the signature and hands back
the Event. It takes four arguments:

1. The raw request body, read as a String before anything parses it. JSON
   that has been parsed and written out again won't verify.
2. The headers. A Hash with names in any case works, and so do a Rack env
   and Rails' `request.headers`.
3. The path the Delivery arrived on, query string included, or the full URL.
   The signature covers the path, so `request.fullpath` is what you want in
   Rack, Sinatra and Rails.
4. The subscription's Signing secret.

`Webhook` never needs API credentials, so an endpoint can skip building a
client. (It also hangs off a client as `client.webhooks`.) In a Sinatra app,
or any Rack app, pass `request.env` as the headers:

<!-- sample: webhook-sinatra -->
```ruby
require "sinatra/base"
require "teachmehipaa"

class TmhWebhooks < Sinatra::Base
  post "/webhooks/tmh" do
    event = TeachMeHipaa::Webhook.construct_event(
      request.body.read,
      request.env,
      ENV.fetch("TMH_WEBHOOK_SECRET"),
      request.fullpath,
    )
    next "test received" if event.is_a?(TeachMeHipaa::TestDelivery)

    "received #{event.event_type}"
  rescue TeachMeHipaa::WebhookSignatureError => e
    halt 400, e.code
  end
end
```

For a Rails controller, see [Rails](rails.md#a-webhook-endpoint).
[`examples/webhook_sinatra.rb`](../../examples/webhook_sinatra.rb) is a
complete endpoint that dispatches on the Event class.

A Delivery signed more than 5 minutes away from your clock, either way, is
rejected, so keep the server's clock synced. A failure raises
`TeachMeHipaa::WebhookSignatureError` with one of these codes:

| `code` | Cause |
| --- | --- |
| `missing_header` | no `x-tmh-signature` or `x-tmh-timestamp` header |
| `invalid_timestamp` | the timestamp isn't an ISO 8601 date-time |
| `body_hash_mismatch` | the body differs from the one that was signed |
| `signature_mismatch` | wrong secret, wrong path or wrong body |
| `timestamp_outside_tolerance` | signed more than 5 minutes from now |

Answer a failure with 400. Answer a good Delivery with a 2xx right away and
push slow work to a background job, because TeachMeHIPAA retries any
Delivery that doesn't get a 2xx.

Deliveries can repeat and arrive out of order. Skip an `event_id` you've
already handled, and sort by `occurred_at`. If your endpoint was down, the
missed Events are still in the [Event log](#the-event-log) for 30 days.

## Test deliveries

`webhook_subscriptions.test` sends your endpoint a signed Test delivery. It
carries no Event, and `construct_event` returns a `TeachMeHipaa::TestDelivery`
for it. The call returns an Operation; wait on it to hear how your endpoint
answered:

<!-- sample: test-delivery -->
```ruby
result = client.webhook_subscriptions.test("whs_01JD8D").wait(timeout: 30).response

case result
when TeachMeHipaa::WebhookDeliverySent then puts "Your endpoint answered #{result.response_status}"
when TeachMeHipaa::WebhookDeliveryFailed then puts "Delivery failed: #{result.reason}"
else puts result.tag
end
```

`webhook_subscriptions.redrive` re-sends the subscription's failed Deliveries
and returns an Operation the same way.

## Signing your own payloads

`Webhook.generate_test_headers` signs a payload the way TeachMeHIPAA does,
so you can exercise a handler with no network at all:

<!-- sample: webhook-test-headers -->
```ruby
require "json"

payload = JSON.generate(
  "eventId" => "evt_01JD8M",
  "eventType" => "learner.certified",
  "orgId" => "org_acme",
  "occurredAt" => "2026-11-15T12:00:00.000Z",
  "data" => {
    "learnerId" => "sub_01JD80AB2C3D4E5F6G7H8J9K0M",
    "email" => "ana@example.com",
    "externalId" => "hr-123",
    "courseId" => "hipaa-2026",
    "status" => "certified",
    "occurredAt" => "2026-11-15T12:00:00.000Z",
  },
)
headers = TeachMeHipaa::Webhook.generate_test_headers(
  payload:, secret: "test-signing-secret", path: "/webhooks/tmh",
)

event = TeachMeHipaa::Webhook.construct_event(payload, headers, "test-signing-secret", "/webhooks/tmh")
puts event.event_type, event.data.learner_id
```

[Testing](testing.md#signed-deliveries) posts the same kind of payload
through a Rack app.
