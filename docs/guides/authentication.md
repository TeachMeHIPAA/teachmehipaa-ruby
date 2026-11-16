# Authentication

The Developer API authenticates with short-lived Access tokens. The client
gets and renews them for you; this guide covers where they come from, what
they allow, and the cases where you supply one yourself or need none.

## Client credentials

An API client is a machine credential: a client id (`cli_…`) and secret
(`tmh_cs_…`) that an Organization admin creates in the TeachMeHIPAA console.
Pass both to the client:

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

The client exchanges the credentials for an Access token on its first call
(the OAuth client-credentials grant), caches the token, and renews it 60
seconds before it expires. Concurrent calls share one token request. If the
API rejects a token mid-flight with a 401, the client renews it once and
replays the call; that replay doesn't count as a retry.

When the token endpoint refuses the credentials (a wrong secret, a revoked
API client, or Sandbox credentials used against Live), the call raises
`TeachMeHipaa::OAuthError`, whose `code` is the OAuth error, such as
`"invalid_client"`.

Never ship a client secret to a browser or a mobile app: the library is for
server-side code.

## Scopes

Each API client holds a set of Scopes, chosen by the admin who created it,
and each method needs one of them. The [resource
reference](../reference/resources.md) lists the Scopes for every method.

| Scope | Allows |
| --- | --- |
| `learners:read` | Reading Learners, and exporting them |
| `learners:write` | Creating, updating, reminding and offboarding Learners, and launch links |
| `enrollments:read` | Reading Enrollments and the Seat inventory, and exporting Enrollments |
| `enrollments:write` | Creating, cancelling, renewing and importing Enrollments, and batch updates |
| `certificates:read` | Reading Certificates, downloading their PDFs, and exporting them |
| `compliance:read` | The Compliance summary |
| `members:read` | Reading Members |
| `audit:read` | Audit events and the Event log |
| `webhooks:manage` | Webhook subscriptions and the Event log |

By default an Access token carries every Scope the API client holds. To ask
for fewer, for a process that only reads, pass `scopes:`:

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

A call that needs a Scope the token lacks raises
`TeachMeHipaa::PermissionDeniedError` (403).

## Environments

Every credential belongs to one Environment, **Live** or **Sandbox**, and
never works in the other. Choose it with `environment:` (`:live` is the
default):

| Environment | `environment:` | Base URL |
| --- | --- | --- |
| Live | `:live` | `https://api.tme.so/v1` |
| Sandbox | `:sandbox` | `https://sandbox.api.tme.so/v1` |

Build and test against Sandbox, then create a separate API client in Live
for production. A Sandbox token's introspection has `mode` `"test"`; a Live
one has `"live"`. `base_url:` overrides the Environment's URL, to point the
client at a mock server; see [Testing](testing.md).

## The Organization binding

An API client belongs to exactly one Organization, so you never pass an
Organization id to a method. On the first call that needs one, the client
calls `auth.introspect` once to learn which Organization its token is for,
and remembers it. If you already know the id, pass it and the client skips
that lookup:

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
Organization, use that Organization's API client, in a client of its own.

## A token you already have

If your system gets Access tokens some other way, hand one to the client
with `TokenProviders::Static` instead of credentials:

<!-- sample: static-token -->
```ruby
client = TeachMeHipaa::Client.new(
  token_provider: TeachMeHipaa::TokenProviders::Static.new(ENV.fetch("TMH_ACCESS_TOKEN")),
  environment: :sandbox,
)

puts client.auth.introspect.expires_at
```

A static token is never renewed: once it expires or is revoked, calls raise
`TeachMeHipaa::AuthenticationError`. Pass either `token_provider:` or
`client_id:` and `client_secret:`, not both; `scopes:` belong to the token
provider. Passing only one of `client_id:` and `client_secret:` raises
`ArgumentError` when the client is created.

A token provider is any object with `access_token(connection)`, which returns
a current Access token, and `invalidate(access_token)`, which forgets one the
API refused. It must be safe to call from several threads.

## Calls without credentials

The course catalog and Certificate verification are public: they need no
Access token, so the client never sends one for them, even when it has
credentials. A client built with no credentials at all can make only these
calls:

<!-- sample: no-credentials -->
```ruby
catalog = TeachMeHipaa::Client.new(environment: :sandbox)

catalog.courses.list.auto_paging_each { |course| puts course.title }
puts catalog.certificate_verifications.retrieve("x7Kq2p").status
```

Any other method on such a client raises `TeachMeHipaa::AuthenticationError`
before it sends a request, as if the API had answered 401.
