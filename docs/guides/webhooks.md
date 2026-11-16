# Webhooks

A Webhook subscription tells TeachMeHIPAA to POST Events of the types you
choose to your endpoint as they happen. Each POST, a Delivery, is signed with
the subscription's Signing secret; your endpoint verifies the signature
before it trusts the Event.

## Create a subscription

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

Store `secret` (the Signing secret) now, somewhere your endpoint can read it:
the API returns it only once. Managing subscriptions needs the
`webhooks:manage` Scope. `webhook_subscriptions.update` changes a
subscription (it requires `if_match:`; see [Conditional
requests](conditional-requests.md)), and `delete` removes it.

## Verify Deliveries

`TeachMeHipaa::Webhook.construct_event` verifies a Delivery and returns its
Event, or a `TeachMeHipaa::TestDelivery` for a [Test
delivery](#test-deliveries). It needs four things, the first three exactly
as they arrived:

1. **The raw body.** Read it as a String before anything parses it. Parsed
   and re-serialized JSON never verifies.
2. **The headers.** A Hash with names in any case works, and so do a Rack
   env (`HTTP_X_TMH_SIGNATURE`) and Rails' `request.headers`.
3. **The request path, with its query string, or the full URL.** The
   signature covers the path the Delivery was sent to, so a verifier that
   drops the path or its query string rejects every Delivery. In Rack,
   Sinatra and Rails that is `request.fullpath`.
4. **The Signing secret** of the subscription.

A Delivery signed more than 5 minutes from your clock, in either direction,
is rejected, so keep your server's clock in sync. Verification failures
raise `TeachMeHipaa::WebhookSignatureError` with a `code`:

| `code` | Meaning |
| --- | --- |
| `missing_header` | The `x-tmh-signature` or `x-tmh-timestamp` header is missing |
| `invalid_timestamp` | The timestamp isn't an ISO 8601 date-time |
| `body_hash_mismatch` | The body isn't the one that was signed |
| `signature_mismatch` | The signature doesn't match: a wrong secret, path or body |
| `timestamp_outside_tolerance` | Signed more than 5 minutes from now |

Answer a verification failure with 400, and a verified Delivery with a 2xx
quickly: do slow work in a background job. TeachMeHIPAA retries a Delivery
that doesn't get a 2xx.

`Webhook` needs only the Signing secret, never API credentials, so an
endpoint doesn't need a client. It is also reachable as `client.webhooks`.

### Rails

Read the body with `request.raw_post`. An `ActionController::API`
controller has no CSRF check; in an `ActionController::Base` controller add
`skip_forgery_protection`, since the signature authenticates the request:

<!-- sample: webhook-rails -->
```ruby
# config/routes.rb: post "/webhooks/tmh", to: "tmh_webhooks#create"
class TmhWebhooksController < ActionController::API
  def create
    event = TeachMeHipaa::Webhook.construct_event(
      request.raw_post,
      request.headers,
      Rails.application.credentials.tmh_webhook_secret,
      request.fullpath,
    )
    if event.is_a?(TeachMeHipaa::EventLearnerCertified)
      CertifiedLearnerJob.perform_later(event.data.learner_id)
    end
    head :ok
  rescue TeachMeHipaa::WebhookSignatureError => e
    render plain: e.code, status: :bad_request
  end
end
```

### Sinatra and Rack

Read `request.body.read` and pass `request.env` as the headers:

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

[`examples/webhook_sinatra.rb`](../../examples/webhook_sinatra.rb) is a
complete endpoint that dispatches on the Event type.

## Handle Events

Events are typed by `event_type`, and Event types this version doesn't know
arrive as a `TeachMeHipaa::UnknownEvent`, so new types never break your
handler. See [Event types](pagination-and-events.md#event-types).

Deliveries can arrive more than once and out of order. Use `event_id` to
skip an Event you have already handled, and `occurred_at` to order them.
Events you missed while your endpoint was down are still in the [Event
log](pagination-and-events.md#the-event-log) for 30 days.

## Test deliveries

`webhook_subscriptions.test` sends your endpoint a signed Test delivery,
which carries no Event: `construct_event` returns a
`TeachMeHipaa::TestDelivery` for it. The call returns an Operation; wait for
it to learn how the Delivery went:

<!-- sample: test-delivery -->
```ruby
result = client.webhook_subscriptions.test("whs_01JD8D").wait(timeout: 30).response

case result
when TeachMeHipaa::WebhookDeliverySent then puts "Your endpoint answered #{result.response_status}"
when TeachMeHipaa::WebhookDeliveryFailed then puts "Delivery failed: #{result.reason}"
else puts result.tag
end
```

`webhook_subscriptions.redrive` retries the subscription's failed Deliveries
the same way.

## Test your handler

To test a handler without TeachMeHIPAA, sign a payload as TeachMeHIPAA does
with `Webhook.generate_test_headers`, then pass the payload and headers to
your handler, or straight to `construct_event`:

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

[Testing](testing.md#sign-test-deliveries) shows the same through a Rack
app.
