# Documentation

Start with the [README](../README.md): it installs the gem and makes the
first calls. The guides pick up from there, and every Ruby block in them runs
in the test suite against a fake API, so the code matches the gem you
install.

## Guides

1. [Setting up a client](guides/client.md): credentials, Live and Sandbox,
   Scopes, the Organization, static tokens, public calls, every option,
   per-call options, timeouts, logging, threads and transports.
2. [Models, pages and ETags](guides/models-and-pages.md): method
   conventions, model readers, `Enumerable` pages, `auto_paging_each` and
   `lazy`, `if_match:`, merge patches and `if_none_match:`.
3. [Errors and retries](guides/errors.md): the error classes, `code`,
   request ids, the retry rules and idempotency keys.
4. [Events and webhooks](guides/events-and-webhooks.md): the Event log,
   Event classes, `events.tail`, subscriptions, verifying Deliveries in
   Rack and Sinatra, Test deliveries.
5. [Operations and files](guides/operations.md): `Operation#wait`, CSV
   exports, Certificate PDFs, CSV imports.
6. [Rails](guides/rails.md): credentials, an initializer, a job, a webhook
   controller and its integration test.
7. [Testing](guides/testing.md): the Sandbox, a fake transport, signed
   Deliveries.
8. [Versions and upgrades](guides/upgrading.md): semantic versioning, Ruby
   support, `OPENAPI_VERSION`, and how API additions reach you.

## Reference

- [Resource reference](reference/resources.md): each method's Ruby call,
  HTTP request, Scopes, retry and conditional behaviour, parameters and
  return type. Generated from `openapi/sdk-ir.json`.
- [`reference/code-samples.json`](reference/code-samples.json): the Ruby
  sample for each operation that the TeachMeHIPAA API reference shows.
  Generated from the same IR, and run by `test/code_samples_test.rb`.
- [API reference](https://teachmehipaa.github.io/teachmehipaa-ruby/): every
  public class, method and model field, built by YARD from the doc comments
  (`bundle exec rake docs` writes it to `doc/`).
- RBS signatures for the public API ship in the gem's `sig/` directory, for
  Steep and RBS-aware editors.

## Examples

[`examples/`](../examples) holds programs you can run against the Sandbox: a
quickstart, a roster sync by External ID, a Sinatra webhook endpoint and a
Certificate export. [`examples/README.md`](../examples/README.md) says how to
run them.

## For contributors

- [CONTRIBUTING.md](../CONTRIBUTING.md): setup, tests, the generator, how
  the docs stay in sync, releasing.
- [`adr/`](adr): architecture decision records, such as why webhook
  verification takes the request path.
- [`design/`](design): the design interview that settled the interface.
- [`research/`](research): how Stripe's Ruby library does things, and what
  this gem borrows.
- [`agents/`](agents): notes for coding agents in this repository.
- [GLOSSARY.md](../GLOSSARY.md): the domain terms the code and docs use.
