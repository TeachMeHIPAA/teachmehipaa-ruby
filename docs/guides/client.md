# Setting up a client

Everything starts with `TeachMeHipaa::Client.new`. You pass keywords and get
back a client whose configuration is frozen, ready to share across your app.
There is no global `TeachMeHipaa.configure`: a different setting means a
second client.

## Credentials

An Organization admin creates an API client in the TeachMeHIPAA console. It
comes with a client id (`cli_…`) and a client secret (`tmh_cs_…`). Hand both
to the client:

<!-- sample: client-credentials -->
```ruby
client = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  environment: :sandbox,
)

token = client.auth.introspect
puts token.client_id, token.scopes.join(" ")
```

On its first call the client trades the credentials for an Access token
(the OAuth client-credentials grant). It caches the token and fetches a new
one 60 seconds before the old one expires. Threads that need a token at the
same moment share a single token request. If the API rejects a token with a
401 partway through its life, the client fetches a fresh one once and
replays the call, and that replay doesn't count against `max_retries`.

A refused secret, a revoked API client, or Sandbox credentials sent to Live
all raise `TeachMeHipaa::OAuthError`. Its `code` holds the OAuth error, such
as `"invalid_client"`.

Keep the secret on your servers. This gem is for server-side Ruby, never
for code that ships to a browser or a phone.

## Live and Sandbox

Each credential belongs to one Environment and fails in the other.
`environment:` picks it, and `:live` is the default:

| Environment | `environment:` | Base URL |
| --- | --- | --- |
| Live | `:live` | `https://api.tme.so/v1` |
| Sandbox | `:sandbox` | `https://sandbox.api.tme.so/v1` |

Build against the Sandbox, then make a second API client in Live for
production. `auth.introspect.mode` is `"test"` for a Sandbox token and
`"live"` for a Live one. `base_url:` overrides both, for a mock server.

## Scopes

The admin picks which Scopes an API client holds, and each method needs one
of them. The [resource reference](../reference/resources.md) names the Scope
for every method.

| Scope | Lets you |
| --- | --- |
| `learners:read` | Read and export Learners |
| `learners:write` | Create, update, remind and offboard Learners, and make launch links |
| `enrollments:read` | Read and export Enrollments, and read the Seat inventory |
| `enrollments:write` | Create, cancel, renew and import Enrollments, and run batch updates |
| `certificates:read` | Read and export Certificates, and download their PDFs |
| `compliance:read` | Read the Compliance summary |
| `members:read` | Read Members |
| `audit:read` | Read Audit events and the Event log |
| `webhooks:manage` | Manage Webhook subscriptions and read the Event log |

A token carries every Scope its API client holds. A process that only reads
can ask for less with `scopes:`:

<!-- sample: scopes -->
```ruby
reader = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  scopes: %w[learners:read compliance:read],
)

begin
  reader.learners.create(email: "ana@example.com")
rescue TeachMeHipaa::PermissionDeniedError => e
  puts "#{e.code}: #{e.detail}"
end
```

A call outside the token's Scopes raises `PermissionDeniedError` (403).

## The Organization

An API client belongs to one Organization, so no method takes an
Organization id. The first call that needs it runs `auth.introspect` once and
remembers the answer. If you already know the id, pass it and skip that
request:

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

To work for another Organization, build another client with that
Organization's API client.

## Bringing your own token

When something else in your system hands out Access tokens, wrap one in
`TokenProviders::Static` and leave the credentials off:

<!-- sample: static-token -->
```ruby
client = TeachMeHipaa::Client.new(
  token_provider: TeachMeHipaa::TokenProviders::Static.new(ENV.fetch("TMH_ACCESS_TOKEN")),
  environment: :sandbox,
)

puts client.auth.introspect.expires_at
```

The client never renews a static token. Once it expires or is revoked, calls
raise `AuthenticationError`.

You pass `token_provider:` or the `client_id:` and `client_secret:` pair,
never both, and `scopes:` goes with the credentials. Half a pair raises
`ArgumentError` from `Client.new`. Your own provider is any object with two
thread-safe methods: `access_token(connection)` returns a current token, and
`invalidate(access_token)` forgets one the API refused.

## Public calls

The course catalog and Certificate verification need no token, and the
client never sends one to them. A client with no credentials at all can make
those calls and nothing else:

<!-- sample: no-credentials -->
```ruby
catalog = TeachMeHipaa::Client.new(environment: :sandbox)

catalog.courses.list.auto_paging_each { |course| puts course.title }
puts catalog.certificate_verifications.retrieve("x7Kq2p").status
```

Any other method on that client raises `AuthenticationError` before a
request leaves your process, as if the API had answered 401.

## Every option

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

| Keyword | Default | What it does |
| --- | --- | --- |
| `client_id` | none, so public calls only | Your API client's id (`cli_…`) |
| `client_secret` | required with `client_id` | Its secret (`tmh_cs_…`) |
| `scopes` | every Scope the API client holds | Narrows the token |
| `token_provider` | client credentials | Supplies tokens instead, such as `TokenProviders::Static` |
| `environment` | `:live` | `:live` or `:sandbox` |
| `base_url` | the Environment's URL | Points the client elsewhere, such as a mock server |
| `organization_id` | looked up once via `auth.introspect` | The Organization to act for |
| `max_retries` | `2` | Retries for a failed call that is safe to replay |
| `timeout` | `80.0` | Seconds to connect, and for each read and write |
| `logger` | none | Gets one `info` line per HTTP exchange, never a body |
| `app_info` | none | `{ name:, version:, url: }`, added to the User-Agent |
| `transport` | `Transport::NetHttp` | Sends each request (see [Testing](testing.md#a-fake-transport)) |
| `clock`, `sleep` | monotonic clock, `Kernel#sleep` | Time and waiting, swappable for tests |

`environment`, `base_url`, `max_retries` and `timeout` have readers on the
client, and `client.config` holds the lot, frozen. An unknown Environment, a
negative timeout and other bad values raise `ArgumentError` from
`Client.new`.

## Options for one call

Every method takes a last `request_options:` Hash:

| Key | Effect |
| --- | --- |
| `idempotency_key` | Replaces the generated `Idempotency-Key` (see [Errors and retries](errors.md#idempotency)) |
| `max_retries` | Overrides the client's retry budget |
| `timeout` | Overrides the client's timeout, in seconds |
| `request_id` | Sent as `x-request-id`, so support can find the call |
| `headers` | Extra request headers |

<!-- sample: per-call-timeout -->
```ruby
summary = client.compliance.retrieve(request_options: { timeout: 5, request_id: "dashboard-refresh" })
puts summary.compliant_rate
```

An unknown key raises `ArgumentError` before anything is sent. The later
pages of a list reuse the first call's request options.

## Timeouts

`timeout:` bounds each phase of a request (the connect, then each read and
write), so a slow call can outlast it. With retries, one call can take
`max_retries + 1` timeouts plus the backoff between them. For a tight
budget, lower both:

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

When the retries run out, the call raises `APITimeoutError`, a kind of
`APIConnectionError`.

## Logging

On its own the gem prints nothing, sends no telemetry and writes no files.
Give it a `logger:` (a `Logger`, `Rails.logger`, or anything that answers
`info`) and it writes one line per HTTP exchange, token requests included:
method, path without the query string, status, latency and request id.
Bodies, headers and credentials stay out of the log, since they carry
Learners' names and emails. The query string stays out because it can hold
an email too.

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

From Ruby 4.0, `logger` is a bundled gem, so list it in your Gemfile before
you `require "logger"`.

Each request's `User-Agent` names the gem, its version and your Ruby.
`app_info:` adds your software's `name`, plus `version` and `url` if you give
them, which helps support pick out your traffic.

## Threads

Share one client across threads. A `Mutex` guards its token cache and its
Organization lookup, so a burst of calls makes one token request and one
lookup. Models and pages come back frozen. The exception is an `EventTail`,
which tracks a position: give each one to a single thread.

## Transports

The default `Transport::NetHttp` opens a `Net::HTTP` connection per request.
To send requests through an HTTP stack your app already has, pass any object
whose `call(request)` returns a `Transport::Response`. The client owns
retries, so a transport sends each request once and raises when no response
arrives, either an `APIConnectionError` or the network errors `Net::HTTP`
raises. [Testing](testing.md#a-fake-transport) has a small one.
