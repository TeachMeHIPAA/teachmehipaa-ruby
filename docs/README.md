# Documentation

The API reference and guides live at
[docs.teachmehipaa.com/api](https://docs.teachmehipaa.com/api?lang=ruby).
The [README](../README.md) installs the gem and makes a first call.

## Reference

- [`reference/code-samples.json`](reference/code-samples.json): the Ruby
  sample for each operation that the hosted API reference shows. Generated
  from `openapi/sdk-ir.json`, and run by `test/code_samples_test.rb`.
- RBS signatures for the public API ship in the gem's `sig/` directory, for
  Steep and RBS-aware editors.

## Examples

[`examples/`](../examples) holds programs you can run against the Sandbox: a
quickstart, a roster sync by External ID, a Sinatra webhook endpoint and a
Certificate export. [`examples/README.md`](../examples/README.md) says how to
run them.

## For contributors

- [CONTRIBUTING.md](../CONTRIBUTING.md): setup, tests, the generator,
  releasing.
- [`adr/`](adr): architecture decision records, such as why webhook
  verification takes the request path.
- [`design/`](design): the design interview that settled the interface.
- [`research/`](research): how Stripe's Ruby library does things, and what
  this gem borrows.
- [`agents/`](agents): notes for coding agents in this repository.
- [GLOSSARY.md](../GLOSSARY.md): the domain terms the code and docs use.
