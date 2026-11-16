# Documentation

Documentation for the TeachMeHIPAA Ruby library. Start with the [project
README](../README.md) for installation and a quickstart.

## Guides

Every Ruby sample in these guides runs in the test suite against a fake
transport, so it matches the library's current behaviour.

- [Getting started](guides/getting-started.md): install, credentials, first
  calls, reading responses.
- [Authentication](guides/authentication.md): client credentials, Scopes, the
  Live and Sandbox Environments, the Organization binding, static tokens and
  calls without credentials.
- [Errors and retries](guides/errors-and-retries.md): error classes, `code`,
  request ids, retries and idempotency keys.
- [Pagination and events](guides/pagination-and-events.md): pages,
  auto-paging, the Event log and `events.tail`.
- [Webhooks](guides/webhooks.md): subscriptions, verifying Deliveries with
  the raw body and exact path, Rails and Sinatra handlers, Test deliveries
  and test headers.
- [Operations and files](guides/operations-and-files.md): `Operation#wait`,
  CSV exports, Certificate PDF downloads and streaming, CSV imports.
- [Conditional requests](guides/conditional-requests.md): ETags,
  `if_match:`, `if_none_match:` and merge-patch updates.
- [Testing](guides/testing.md): the Sandbox, injecting a fake transport and
  signing test Deliveries.
- [Configuration](guides/configuration.md): every client option and its
  default, request options, logging, timeouts and thread safety.
- [Versioning](guides/versioning.md): semantic versioning, `OPENAPI_VERSION`
  and how API additions reach you.

## API reference

- [Resource reference](reference/resources.md): every resource method with
  its Ruby call, HTTP request, Scopes, retry and conditional behaviour,
  parameters and return type. Generated from `openapi/sdk-ir.json`.
- [API reference](https://teachmehipaa.github.io/teachmehipaa-ruby/): every
  public class, method and model field, built with YARD from the code's doc
  comments (`bundle exec rake docs` builds it locally into `doc/`).
- RBS signatures for every public class and method ship in the gem's `sig/`
  directory, for Steep and editors with RBS support.

## Examples

[`examples/`](../examples) holds small programs that run against the Sandbox:
a quickstart, a roster sync by External ID, a Sinatra webhook endpoint, and
a Certificate export. See [`examples/README.md`](../examples/README.md).

## Contributing / design records

For people working on the library rather than with it:

- [CONTRIBUTING.md](../CONTRIBUTING.md): setup, tests, the generator, how the
  docs are built and kept in sync, and releasing.
- [`adr/`](adr): architecture decision records, such as why webhook
  verification takes the request path.
- [`design/`](design): the design interview that settled the library's
  interface.
- [`research/`](research): how Stripe's Ruby library does things, and what
  this library adopts from it.
- [`agents/`](agents): notes for coding agents working in this repository.
- [GLOSSARY.md](../GLOSSARY.md): the domain terms the code and docs use.
