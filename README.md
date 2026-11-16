# TeachMeHIPAA Ruby Library

Enroll Learners in HIPAA training and track their compliance from your own
Ruby code, through the TeachMeHIPAA Developer API.

[![CI](https://github.com/TeachMeHIPAA/teachmehipaa-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/TeachMeHIPAA/teachmehipaa-ruby/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> [!IMPORTANT]
> **Status: pre-release.** The TeachMeHIPAA Developer API isn't generally
> available yet, and this gem isn't published to RubyGems. Until it is,
> install it from this GitHub repository (below). Expect changes before 1.0.

The library handles Access tokens, the Organization binding, retries,
idempotency keys, typed errors, pagination, ETags, Operations and webhook
verification, so your code only calls methods. It has no runtime
dependencies, sends no telemetry and never logs request bodies.

## Installation

Ruby 3.2 or newer. Add the gem to your Gemfile from GitHub, then run
`bundle install`:

<!-- sample: install -->
```ruby
# Gemfile
gem "teachmehipaa", git: "https://github.com/TeachMeHIPAA/teachmehipaa-ruby"
```

Once it is on RubyGems, `gem "teachmehipaa"` will replace that line.

## Quickstart

Create an API client in the TeachMeHIPAA console to get a client id
(`cli_…`) and secret (`tmh_cs_…`), and start in the Sandbox Environment:

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

The [getting started guide](docs/guides/getting-started.md) walks through
your first calls, and [`examples/`](examples) has small programs you can run
against the Sandbox.

## Documentation

| Topic | Guide |
| --- | --- |
| Install, first calls, reading responses | [Getting started](docs/guides/getting-started.md) |
| Client credentials, Scopes, Live and Sandbox, the Organization binding, static tokens, public lookups | [Authentication](docs/guides/authentication.md) |
| Error classes, `code`, request ids, retries, idempotency keys | [Errors and retries](docs/guides/errors-and-retries.md) |
| Auto-paging, the Event log, `events.tail` | [Pagination and events](docs/guides/pagination-and-events.md) |
| Verifying Deliveries, Test deliveries, Rails and Sinatra handlers | [Webhooks](docs/guides/webhooks.md) |
| `Operation#wait`, CSV exports, Certificate PDFs, CSV imports | [Operations and files](docs/guides/operations-and-files.md) |
| ETags, `if_match:`, `if_none_match:`, merge-patch updates | [Conditional requests](docs/guides/conditional-requests.md) |
| The Sandbox, fake transports, signing test Deliveries | [Testing](docs/guides/testing.md) |
| Every client option, logging, timeouts, thread safety | [Configuration](docs/guides/configuration.md) |
| Semantic versioning, `OPENAPI_VERSION`, API additions | [Versioning](docs/guides/versioning.md) |

Every resource method, with its HTTP request, Scopes and parameters, is in
the [resource reference](docs/reference/resources.md). The
[API reference](https://teachmehipaa.github.io/teachmehipaa-ruby/), built with
YARD, documents every class and field; [`docs/`](docs/README.md) lists
everything.

## Support and security

<!-- TODO(Nick): confirm the support address before launch. -->

For help, contact TeachMeHIPAA support and quote the `request_id` from the
error or `last_response`. To report a vulnerability, see
[SECURITY.md](SECURITY.md); please don't open a public issue.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The library is MIT licensed; see
[LICENSE](LICENSE).
