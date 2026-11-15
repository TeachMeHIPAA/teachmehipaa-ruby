# TeachMeHIPAA Ruby Library

The official Ruby library for the
[TeachMeHIPAA Developer API](https://api.tme.so/v1). It handles Access tokens,
the Organization binding, retries, idempotency keys, typed errors, pagination,
ETags, Operations and webhook verification, so your code only calls methods.

> [!NOTE]
> The Developer API has not launched yet, and this gem is not on RubyGems.
> Until it is, install it from GitHub (see below).

## Contents

- [Installation](#installation)
- [Quickstart](#quickstart)
- [The Organization binding](#the-organization-binding)
- [Calls without credentials](#calls-without-credentials)
- [Creating Learners](#creating-learners)
- [Pagination](#pagination)
- [Errors](#errors)
- [Retries and idempotency](#retries-and-idempotency)
- [Request options](#request-options)
- [Conditional writes and reads](#conditional-writes-and-reads)
- [Operations](#operations)
- [Uploads and downloads](#uploads-and-downloads)
- [Webhooks](#webhooks)
- [Tailing the Event log](#tailing-the-event-log)
- [Configuration](#configuration)
- [Logging](#logging)
- [Thread safety](#thread-safety)
- [Types](#types)
- [Versioning](#versioning)
- [Support and security](#support-and-security)

## Installation

<!-- sample: install -->
```ruby
# Gemfile
gem "teachmehipaa", git: "https://github.com/TeachMeHIPAA/teachmehipaa-ruby"
# once it is on RubyGems, instead:
# gem "teachmehipaa"
```

Ruby 3.2 or newer. The gem has no runtime dependencies: it uses only the
standard library (`net/http`, `openssl`, `json`, `securerandom`).

## Quickstart

Create an API client in the TeachMeHIPAA console to get a client id
(`cli_…`) and secret (`tmh_cs_…`). Start in the Sandbox Environment, where no
real Learners are emailed and no real money moves.

<!-- sample: quickstart -->
```ruby
require "teachmehipaa"

client = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  environment: :sandbox,
)

learner = client.learners.retrieve("sub_01JD80AB2C3D4E5F6G7H8J9K0M")
puts "#{learner.name}: #{learner.status}"

client.learners.list(status: "in_progress", limit: 20).auto_paging_each do |item|
  puts item.email
end
```

The client exchanges your credentials for an Access token on the first call,
caches it and renews it 60 seconds before it expires. Concurrent calls share
one token request. If the API rejects a token mid-flight (401), the client
renews it once and replays the call; that replay doesn't count as a retry.

Methods take keyword arguments, except ids in the path, which come first and
positionally: `client.learners.retrieve(learner_id, course_id: ...)`. Every
object they return has a `last_response` with the HTTP `status`, `headers`,
`request_id` and `etag`. Fields are snake_case readers (`learner.learner_id`);
`learner["someNewField"]` reads a field this version doesn't know yet, and
`to_h` returns them all.

To ask for fewer Scopes than your API client holds, pass
`scopes: ["learners:read"]`.

## The Organization binding

An API client belongs to one Organization, so you never pass an `org_id`. On
the first Organization-scoped call, the client asks `auth.introspect` which
Organization the token is for, once, and remembers the answer. If you already
know the id, pass it and the client skips that lookup:

<!-- sample: organization -->
```ruby
client = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  organization_id: "org_acme",
)

compliance = client.compliance.retrieve
puts compliance.compliant_rate, compliance.last_response.request_id
```

A client's configuration is fixed when you create it. To act for another
Organization, create another client.

## Calls without credentials

The course catalog and Certificate verification need no Access token, so the
client sends none for them, even when it has credentials. A client built
with neither credentials nor a token provider can make only these calls:

<!-- sample: no-credentials -->
```ruby
catalog = TeachMeHipaa::Client.new(environment: :sandbox)

catalog.courses.list.auto_paging_each { |course| puts course.title }
puts catalog.certificate_verifications.retrieve("x7Kq2p").status
```

Any other method on such a client raises `AuthenticationError` before it
sends a request: the call can't be authenticated, just as if the API had
answered 401. Passing only one of `client_id:` and `client_secret:` is a
mistake in the code, so it raises `ArgumentError` when the client is
created.

## Creating Learners

`create` and `upsert_by_external_id` say whether they created the Learner
with `created?`. `upsert_by_external_id` is safe to replay from a sync job: it
creates and invites the Learner the first time and returns them every time
after.

<!-- sample: learner-writes -->
```ruby
created = client.learners.create(email: "ana@example.com", name: "Ana Example", course_id: "hipaa-2026")
puts created.created? ? "invited" : "already enrolled"

synced = client.learners.upsert_by_external_id("hr-123", email: "ana@example.com", name: "Ana Example")
puts synced.learner_id
```

Samples from here on assume a `client` created as in the
[Quickstart](#quickstart).

## Pagination

A list method returns one `TeachMeHipaa::Page`, with `items` and
`next_cursor`. Like Stripe's list objects, the page is `Enumerable` over its
own items only. `auto_paging_each` yields every item across all pages,
fetching the next page only when the loop reaches it, and stops fetching when
you `break`. Without a block it returns an `Enumerator`, so `lazy` and
`first(n)` fetch only the pages they need.

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

`each_page` yields each page in turn. Later pages repeat the first call's
filters, limit and request options.

## Errors

Failed calls raise a subclass of `TeachMeHipaa::Error` (a `StandardError`),
chosen by HTTP status:

| Class                     | When                                                       |
| ------------------------- | ---------------------------------------------------------- |
| `InvalidRequestError`     | 400, 405, 406, 415 and 422                                 |
| `IdempotencyError`        | 422 `idempotency_key_reuse` (an `InvalidRequestError`)     |
| `AuthenticationError`     | 401, or a client without credentials calling a method that needs them |
| `PermissionDeniedError`   | 403, such as a missing Scope                               |
| `NotFoundError`           | 404                                                        |
| `ConflictError`           | 409                                                        |
| `PreconditionFailedError` | 412 (stale ETag) and 428 (missing `if_match:`)             |
| `RateLimitError`          | 429, with `retry_after` in seconds                         |
| `APIError`                | 5xx, or a response that isn't JSON (such as an HTML page)  |
| `APIConnectionError`      | No response arrived                                        |
| `APITimeoutError`         | No response within `timeout` (an `APIConnectionError`)     |
| `OAuthError`              | The token endpoint refused to issue a token                |
| `OperationFailedError`    | An Operation you waited on finished with an error          |
| `OperationTimeoutError`   | An Operation was not done within `wait`'s `timeout`        |
| `WebhookSignatureError`   | A webhook Delivery failed verification                     |

All of them live under `TeachMeHipaa`. Each error carries the problem's
`code` (branch on it; new codes can appear at any time), `title`, `detail`,
field-level `errors`, the `status`, the response `headers` and the
`request_id` to quote to support. The message ends with the request id too.

<!-- sample: errors -->
```ruby
begin
  client.learners.retrieve("sub_01JD80AB2C3D4E5F6G7H8J9K0M")
rescue TeachMeHipaa::NotFoundError
  puts "No such Learner"
rescue TeachMeHipaa::PermissionDeniedError => e
  puts "Missing a Scope: #{e.detail}"
rescue TeachMeHipaa::Error => e
  puts "#{e.code}: #{e.detail} (request #{e.request_id})"
  e.errors.each { |field| puts "#{field.path}: #{field.message}" }
end
```

## Retries and idempotency

The client retries network errors, 409 `conflict`, 429 and 5xx up to
`max_retries` times (2 by default), backing off from 0.5 s up to 5 s with
jitter and honoring `Retry-After` up to 60 s. It only retries calls that are
safe to replay: reads, writes that carry an `Idempotency-Key`, and the few
writes that are idempotent by nature, such as `learners.create_launch_link`.
PATCH and DELETE are never retried, even with your own key.

Every create and custom method gets a generated UUID `Idempotency-Key`,
reused by each of its retries, so a retry never enrolls a Learner twice.
Pass your own (below) to make a call safe to repeat across processes.

## Request options

Every method takes a trailing `request_options:` Hash for one call:

| Option            | Description                                                                      |
| ----------------- | -------------------------------------------------------------------------------- |
| `idempotency_key` | Replaces the generated `Idempotency-Key`                                         |
| `max_retries`     | Overrides the client's `max_retries`                                             |
| `timeout`         | Overrides the client's `timeout`, in seconds                                     |
| `request_id`      | Sent as `x-request-id`, to correlate your logs with TeachMeHIPAA support         |
| `headers`         | Extra request headers, as a Hash                                                 |

<!-- sample: request-options -->
```ruby
enrollment = client.enrollments.create(
  email: "ana@example.com",
  course_id: "hipaa-2026",
  request_options: {
    idempotency_key: "hr-sync-2026-11-15-ana",
    max_retries: 5,
    timeout: 10,
    request_id: "hr-sync-42",
  },
)
puts enrollment.enrollment_id, enrollment.last_response.request_id
```

The API keeps a `request_id` that matches `/\A[A-Za-z0-9._-]{1,128}\z/` and
replaces any other with its own. An unknown option raises `ArgumentError`
before anything is sent.

## Conditional writes and reads

Updates that the API guards with ETags take `if_match:`: the ETag String, or
the object you read, whose `last_response.etag` the client sends.
`learners.update` and `webhook_subscriptions.update` require it, since the
API refuses them without one; on `learners.offboard` it is optional. A stale
ETag raises `PreconditionFailedError`.

Updates are merge patches. A keyword you leave out is not sent and stays
unchanged; `nil` is sent as JSON `null` and clears the field.

<!-- sample: conditional-write -->
```ruby
learner = client.learners.retrieve("sub_01JD80AB2C3D4E5F6G7H8J9K0M")
begin
  updated = client.learners.update(learner.learner_id, if_match: learner, name: "Ana Q. Example", external_id: nil)
  puts updated.name
rescue TeachMeHipaa::PreconditionFailedError
  puts "Someone else changed this Learner; read it again"
end
```

A retrieve that takes `if_none_match:` returns `TeachMeHipaa::NotModified`
when your copy is still current (304). Everything a method returns answers
`not_modified?`:

<!-- sample: not-modified -->
```ruby
course = client.courses.retrieve("hipaa-2026")

latest = client.courses.retrieve("hipaa-2026", if_none_match: course)
course = latest unless latest.not_modified?
puts course.title
```

## Operations

Exports, imports, batch writes, Test deliveries and redrives return a
`TeachMeHipaa::Operation`. `wait` polls until it is done (backing off from
`interval:`, default 1 s, to 10 s) and raises `OperationTimeoutError` after
`timeout:` (default 300 s), or `OperationFailedError` if it finished with an
error; both carry the `operation`. An Operation that is already done, as
exports always are, returns without a request. An export's `export_result`
hands back the CSV.

<!-- sample: operations -->
```ruby
export = client.learners.export(format: "csv", course_id: "hipaa-2026").wait(timeout: 60).export_result
puts "#{export.filename}: #{export.row_count} rows"

result = client.webhook_subscriptions.test("whs_01JD8D").wait(timeout: 30, interval: 2).response
puts result.tag # "sent", "failed" or "settled"
```

`TeachMeHipaa::Operation.operation_id_from_name(operation.name)` gives the id
that `operations.retrieve` takes, if you want to check on an Operation later.

## Uploads and downloads

An Enrollment import takes the CSV as a path (a String or a `Pathname`), an
IO opened in binary mode, or a `TeachMeHipaa::FilePart`. A String is always a
path, so wrap CSV text you already hold in a `FilePart`. The file is read
once per call, so a retry resends the same bytes.

Certificate PDFs come back whole as a `TeachMeHipaa::BinaryResponse` (`data`,
`content_type`, `filename`). Given a block, `download_pdf` streams the body
to it in chunks instead and returns the `content_type` and `filename`; only a
successful PDF response reaches the block, and once it has received bytes the
call is never retried.

<!-- sample: files -->
```ruby
preview = client.enrollments.preview_import(file: "roster.csv", options: { course_id: "hipaa-2026" })
puts "#{preview.valid_rows} of #{preview.total_rows} rows are valid"
client.enrollments.import(file: Pathname("roster.csv")).wait

csv = "email,name\r\nana@example.com,Ana Example\r\n"
client.enrollments.import(file: TeachMeHipaa::FilePart.new(csv, filename: "march.csv"))

pdf = client.certificates.download_pdf("cert_01JD8F")
File.binwrite(pdf.filename || "certificate.pdf", pdf.data)

File.open("certificate-copy.pdf", "wb") do |file|
  client.certificates.download_pdf("cert_01JD8F") { |chunk| file.write(chunk) }
end
```

## Webhooks

`TeachMeHipaa::Webhook.construct_event` verifies a Delivery and returns its
Event, or a `TeachMeHipaa::TestDelivery` for a Test delivery. It needs three
things exactly as they arrived:

1. **The raw body.** Parsed and re-serialized JSON never verifies, so read
   the body as a String before anything parses it.
2. **The headers.** A Hash with names in any case works, and so do a Rack
   env (`HTTP_X_TMH_SIGNATURE`) and Rails' `request.headers`.
3. **The request path, with its query string, or the full URL.** The
   signature covers the path the Delivery was sent to, so a verifier that
   drops the path, or its query string, rejects every Delivery. In Rack,
   Sinatra and Rails that is `request.fullpath`.

Deliveries signed more than 5 minutes from your clock, in either direction,
are rejected. Verification raises `WebhookSignatureError` with a `code` such
as `"signature_mismatch"`; answer it with 400. Events are typed by
`event_type` (`TeachMeHipaa::EventLearnerCertified` and so on), and Event
types this version doesn't know arrive as a `TeachMeHipaa::UnknownEvent`, so
new types never break your handler.

`Webhook` needs only the Signing secret, never API credentials, so a handler
can use it without creating a client. It is also reachable as
`client.webhooks`.

With **Rails**, read the body with `request.raw_post`. An `ActionController::API`
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

With **Sinatra** (or any Rack app), read `request.body.read` and pass
`request.env` as the headers:

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

To test your handler, sign a payload the way TeachMeHIPAA does with
`Webhook.generate_test_headers`:

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

## Tailing the Event log

`events.tail` reads the Event log oldest first and keeps its own position in
`last_event_id`. Save it, and resume from it after a restart to catch up on
anything you missed while down, without webhooks. Here `cursor_store` stands
in for your own storage and `shutting_down?` for your service's stop signal:

<!-- sample: events-tail -->
```ruby
tail = client.events.tail(after: cursor_store.load, follow: true, interval: 5, stop: -> { shutting_down? })
tail.each do |event|
  puts "#{event.event_type} #{event.event_id}"
  cursor_store.save(tail.last_event_id)
end
```

Without `follow:`, the loop ends once it has caught up. With it, the tail
polls every `interval` seconds until you `break` or `stop` returns true.
`after: nil` starts at the oldest retained Event.

## Configuration

<!-- sample: configuration -->
```ruby
require "logger"

client = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  environment: :sandbox,
  scopes: %w[learners:read learners:write],
  organization_id: "org_acme",
  max_retries: 3,
  timeout: 30,
  logger: Logger.new($stderr),
  app_info: { name: "acme-hr-sync", version: "4.2.0", url: "https://acme.example" },
)
puts client.environment, client.base_url, client.max_retries, client.timeout
puts client.config.frozen?
```

Every option is a keyword:

| Option            | Default                               | Description                                                                         |
| ----------------- | ------------------------------------- | ----------------------------------------------------------------------------------- |
| `client_id`       | None: public methods only             | Your API client's id (`cli_…`)                                                      |
| `client_secret`   | Required with `client_id`             | The matching secret (`tmh_cs_…`)                                                    |
| `scopes`          | Every Scope the API client holds      | Narrows the Access token's Scopes                                                   |
| `token_provider`  | Client credentials                    | Supplies Access tokens instead, such as `TokenProviders::Static`                    |
| `environment`     | `:live`                               | `:live` or `:sandbox`; credentials only work in their own                           |
| `base_url`        | The Environment's URL                 | Overrides it, e.g. to point at a mock server                                        |
| `organization_id` | Looked up once with `auth.introspect` | The Organization to act for                                                         |
| `max_retries`     | `2`                                   | Retries of a failed call that is safe to replay                                     |
| `timeout`         | `80.0`                                | Seconds to wait to connect, and for each read and write                             |
| `logger`          | None                                  | Receives one `info` line per HTTP exchange, never bodies (see [Logging](#logging))  |
| `app_info`        | None                                  | `{ name:, version:, url: }` of your software, sent in the User-Agent                |
| `transport`       | `Transport::NetHttp`                  | Sends requests, e.g. through a proxy, with mTLS or a test fake (see below)          |
| `clock`, `sleep`  | Monotonic clock, `Kernel#sleep`       | Supply the time and waits, for tests                                                |

Pass either `client_id:` and `client_secret:`, or `token_provider:`, not
both (or neither, for [calls without credentials](#calls-without-credentials));
`scopes:` then belong to the token provider. If you get Access tokens some
other way, pass
`token_provider: TeachMeHipaa::TokenProviders::Static.new(access_token)`. A
static token is never renewed; once it expires, calls raise
`AuthenticationError`.

Base URLs: Live is `https://api.tme.so/v1`; Sandbox is
`https://api-teachmehipaa-dev.web.app/v1`.
`environment`, `base_url`, `max_retries` and `timeout` can be read back from
the client. The configuration is frozen when the client is created; there is
no global configuration, so build another client for other settings.

A transport is any object whose `call(request)` takes a
`TeachMeHipaa::Transport::Request` (`http_method`, `url`, `headers`, `body`,
`timeout`) and returns a `TeachMeHipaa::Transport::Response` (`status`,
`headers`, `body`). The library owns retries, so a transport sends each
request exactly once.

## Logging

The library prints nothing, sends no telemetry and writes nothing to disk.
Given a `logger:` (a `Logger`, `Rails.logger` or anything with `info`), it
logs one line per HTTP exchange, token requests included, with the method,
the path (without its query string, which can hold Learner emails), the
status, the latency and the request id. Request and response bodies, headers
and credentials are never logged (ADR-0007), because they hold Learner
details. (From Ruby 4.0, `logger` is a bundled gem: add it to your Gemfile to
`require "logger"`.)

<!-- sample: logging -->
```ruby
require "logger"

client = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  logger: Logger.new($stdout),
)
client.learners.list
# I, [2026-11-15T12:00:00.123 #4242]  INFO -- : teachmehipaa.request method=GET
#   path=/v1/organizations/org_acme/learners status=200 elapsed_ms=84 request_id=req_7f3c2a
```

## Thread safety

A client is safe to share between threads, and sharing one is better than
creating one per thread: its token cache and Organization lookup are guarded
by a `Mutex`, so concurrent calls share one token request and one lookup. A
`Page` is frozen. An `EventTail` keeps a position, so use each tail from one
thread at a time.

## Types

Every public class and method has an [RBS](https://github.com/ruby/rbs)
signature in the gem's `sig/` directory, generated alongside the resources
and models, so Steep and editors with RBS support check and complete your
calls. Doc comments on every resource method and model field come from the
API reference.

## Versioning

The library follows semantic versioning. Its resources and models are
generated from the Developer API's OpenAPI document; `OPENAPI_VERSION` in
this repository names the document release this version was generated from.
Models are tolerant: unknown response fields are kept (read them with `[]`),
and enum fields accept values this version doesn't know, so API additions
don't break your code. See the [changelog](CHANGELOG.md).

## Support and security

<!-- TODO(Nick): confirm the support address before launch. -->

For help, contact TeachMeHIPAA support and quote the `request_id` from the
error or `last_response`. To report a vulnerability, see
[SECURITY.md](SECURITY.md); please don't open a public issue.

See [CONTRIBUTING.md](CONTRIBUTING.md) to work on the library.
