# Configuration

Everything about a client is set when you create it, as keywords to
`TeachMeHipaa::Client.new`. There is no global configuration: to use other
settings, create another client.

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

## Client options

| Option | Default | Description |
| --- | --- | --- |
| `client_id` | None: public methods only | Your API client's id (`cli_…`) |
| `client_secret` | Required with `client_id` | The matching secret (`tmh_cs_…`) |
| `scopes` | Every Scope the API client holds | Narrows the Access token's Scopes |
| `token_provider` | Client credentials | Supplies Access tokens instead, such as `TokenProviders::Static` |
| `environment` | `:live` | `:live` or `:sandbox`; credentials only work in their own |
| `base_url` | The Environment's URL | Overrides it, such as for a mock server |
| `organization_id` | Looked up once with `auth.introspect` | The Organization to act for |
| `max_retries` | `2` | Retries of a failed call that is safe to replay |
| `timeout` | `80.0` | Seconds to wait to connect, and for each read and write |
| `logger` | None | Receives one `info` line per HTTP exchange, never bodies |
| `app_info` | None | `{ name:, version:, url: }` of your software, sent in the User-Agent |
| `transport` | `Transport::NetHttp` | Sends each request; see [Testing](testing.md#a-fake-transport) |
| `clock`, `sleep` | Monotonic clock, `Kernel#sleep` | Supply the time and the waits, for tests |

[Authentication](authentication.md) covers the credential options and
Environments. `environment`, `base_url`, `max_retries` and `timeout` can be
read back from the client, and `client.config` holds them all, frozen.

An invalid option, such as an unknown Environment or a negative timeout,
raises `ArgumentError` when the client is created.

## Request options

Every method takes a trailing `request_options:` Hash that applies to that
call only:

| Option | Description |
| --- | --- |
| `idempotency_key` | Replaces the generated `Idempotency-Key` (see [Errors and retries](errors-and-retries.md#idempotency)) |
| `max_retries` | Overrides the client's `max_retries` |
| `timeout` | Overrides the client's `timeout`, in seconds |
| `request_id` | Sent as `x-request-id`, to correlate your logs with TeachMeHIPAA support |
| `headers` | Extra request headers, as a Hash |

<!-- sample: per-call-timeout -->
```ruby
summary = client.compliance.retrieve(request_options: { timeout: 5, request_id: "dashboard-refresh" })
puts summary.compliant_rate
```

An unknown option raises `ArgumentError` before anything is sent. Later
pages of a list repeat the first call's request options.

## Timeouts

`timeout:` bounds each phase of a request: connecting, and each read and
write. It is not a deadline for the whole call: a call that is retried can
take up to `max_retries + 1` timeouts plus the waits between them. For a
tight overall budget, lower both:

<!-- sample: tight-budget -->
```ruby
fast = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  timeout: 5,
  max_retries: 1,
)
puts fast.timeout
```

A request with no response in time raises `APITimeoutError`, an
`APIConnectionError`, once its retries are spent.

## Logging

The library prints nothing, sends no telemetry and writes nothing to disk.
Given a `logger:` (a `Logger`, `Rails.logger` or anything with `info`), it
logs one line per HTTP exchange, token requests included, with the method,
the path (without its query string, which can hold Learner emails), the
status, the latency and the request id. Request and response bodies, headers
and credentials are never logged, because they hold Learner details.

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

From Ruby 4.0, `logger` is a bundled gem rather than a default one: add it
to your Gemfile to `require "logger"`.

## The User-Agent

Every request's `User-Agent` names the library, its version and your Ruby.
`app_info:` adds your software's `name`, and optionally its `version` and
`url`, which helps TeachMeHIPAA support find your requests.

## Thread safety

A client is safe to share between threads, and sharing one is better than
creating one per thread: its token cache and Organization lookup are guarded
by a `Mutex`, so concurrent calls share one token request and one lookup.
Returned models and pages are frozen. An `EventTail` keeps a position, so
use each tail from one thread at a time.

## Transports

The default transport, `Transport::NetHttp`, opens a `Net::HTTP` connection
per request. To send requests another way, through an HTTP client your
application already uses for instance, pass any object whose
`call(request)` returns a `Transport::Response`. The library owns retries,
so a transport sends each request exactly once, and raises (any
`APIConnectionError`, or the network errors `Net::HTTP` raises) when no
response arrives. [Testing](testing.md#a-fake-transport) shows a minimal
one.
