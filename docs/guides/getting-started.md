# Getting started

This guide installs the library, makes your first calls against the Sandbox
Environment, and shows how to read what comes back.

## Install

The library needs Ruby 3.2 or newer and has no runtime dependencies. It is
not on RubyGems yet, so install it from GitHub. In your Gemfile:

<!-- sample: install -->
```ruby
gem "teachmehipaa", git: "https://github.com/TeachMeHIPAA/teachmehipaa-ruby"
```

Then run `bundle install`. To try it outside a Bundler project, build and
install the gem from a clone:

```sh
git clone https://github.com/TeachMeHIPAA/teachmehipaa-ruby.git
cd teachmehipaa-ruby
gem build teachmehipaa.gemspec
gem install ./teachmehipaa-*.gem
```

## Get credentials

An Organization admin creates an API client in the TeachMeHIPAA console. It
has a client id (`cli_…`) and a client secret (`tmh_cs_…`), belongs to one
Organization, and holds the Scopes the admin chose. Create it in the
**Sandbox** Environment while you build. Keep the secret on your server, in
an environment variable or a secrets manager:

```sh
export TMH_CLIENT_ID=cli_...
export TMH_CLIENT_SECRET=tmh_cs_...
```

## Make your first calls

<!-- sample: first-calls -->
```ruby
require "teachmehipaa"

client = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  environment: :sandbox,
)

created = client.learners.create(email: "ana@example.com", name: "Ana Example")
puts created.created? ? "Invited #{created.email}" : "#{created.email} was already enrolled"

summary = client.compliance.retrieve
puts "#{(summary.compliant_rate * 100).round}% of Learners are compliant"
```

On the first call the client exchanges your credentials for an Access token
and asks the API which Organization it belongs to; it caches both. You never
pass an Organization id. See [Authentication](authentication.md).

Every resource hangs off the client: `client.learners`,
`client.enrollments`, `client.certificates`, `client.compliance`,
`client.courses`, `client.members`, `client.seats`, `client.audit_events`,
`client.webhook_subscriptions`, `client.events`, `client.operations`,
`client.certificate_verifications` and `client.auth`. The
[resource reference](../reference/resources.md) lists every method.

## Call conventions

- Ids in the path come first and positionally; everything else is a keyword:
  `client.learners.retrieve(learner_id, course_id: "hipaa-2026")`.
- Keywords are snake_case versions of the API's names (`external_id:` for
  `externalId`).
- Enum values are plain Strings (`status: "in_progress"`); Symbols work too.
- Every method takes a trailing `request_options:` Hash for one call (see
  [Configuration](configuration.md#request-options)).

## Read responses

Methods return models with snake_case readers. Each top-level object also
carries `last_response`, with the HTTP `status`, `headers`, `request_id` and
`etag`:

<!-- sample: responses -->
```ruby
learner = client.learners.retrieve("sub_01JD80AB2C3D4E5F6G7H8J9K0M")

puts learner.email
puts learner.course.title
puts learner.certificate&.expires_at || "not certified yet"
puts learner.last_response.request_id
puts learner.to_h[:status]
```

Models are tolerant: fields this version of the library doesn't know yet are
kept, and `learner["someNewField"]` reads them by the API's name. `to_h`
returns every field. List methods return a `TeachMeHipaa::Page`; see
[Pagination and events](pagination-and-events.md).

When a call fails, the client raises a subclass of `TeachMeHipaa::Error`;
see [Errors and retries](errors-and-retries.md).

## Next steps

- [Authentication](authentication.md): Scopes, Live and Sandbox, static
  tokens.
- [Webhooks](webhooks.md): get told when a Learner is certified.
- [Testing](testing.md): test your integration without the network.
- [`examples/`](../../examples): runnable programs for a roster sync, a
  webhook endpoint and a Certificate export.
