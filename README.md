# teachmehipaa

A Ruby client for the TeachMeHIPAA Developer API. Invite Learners to HIPAA
training from your own app, and hear about their Certificates the moment
they're issued.

[![CI](https://github.com/TeachMeHIPAA/teachmehipaa-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/TeachMeHIPAA/teachmehipaa-ruby/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> [!IMPORTANT]
> **Pre-release.** The Developer API isn't generally available yet, and the
> gem isn't on RubyGems. Until both happen, point Bundler at this repository.
> The interface can still change before 1.0.

## Requirements

Ruby 3.2 or newer. CI runs the suite on 3.2, 3.3 and 3.4. The gem has no
runtime dependencies: it talks to the API through `Net::HTTP` and parses
JSON with the standard library.

## Installation

Add the gem to your Gemfile, straight from GitHub:

<!-- sample: install -->
```ruby
gem "teachmehipaa", git: "https://github.com/TeachMeHIPAA/teachmehipaa-ruby"
```

Then run `bundle install`. Bundler records the commit it fetched in
`Gemfile.lock`, so every machine gets the same code until you run
`bundle update teachmehipaa`. Add `ref:` with a commit SHA to pin one on
purpose. Once the gem reaches RubyGems, `gem "teachmehipaa"` replaces the
whole line.

## Usage

You need an API client from the TeachMeHIPAA console: a client id
(`cli_…`) and a secret (`tmh_cs_…`). Make it in the Sandbox while you build.

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

client.learners.list(status: :in_progress).auto_paging_each do |person|
  puts person.email
end
```

The client fetches an Access token on its first call, finds your
Organization from it, and keeps both for later calls. You never pass an
Organization id.

A few habits run through the whole library:

- Ids in the URL go first, as positional arguments. Everything else is a
  keyword, in snake_case: `external_id:` for the API's `externalId`.
- Enum values can be Symbols or Strings. Readers always hand back Strings.
- Models answer snake_case readers and `[]`, and `to_h` hands back a Hash
  with Symbol keys.
- A list returns a `TeachMeHipaa::Page`, which is `Enumerable` over its own
  items. `auto_paging_each` walks every page, and without a block it
  returns an `Enumerator` you can make `lazy`.
- Failures raise subclasses of `TeachMeHipaa::Error`.

### In a Rails app

Create one client in an initializer and share it: it is thread-safe. The
[Rails guide](docs/guides/rails.md) has the initializer, credentials, a
webhook controller and a background job.

## Guides

- [Setting up a client](docs/guides/client.md): credentials, Live and
  Sandbox, Scopes, every option, logging, threads.
- [Models, pages and ETags](docs/guides/models-and-pages.md): reading what
  comes back, paging with `Enumerable`, safe updates.
- [Errors and retries](docs/guides/errors.md): which class to rescue, what
  the client retries, idempotency keys.
- [Events and webhooks](docs/guides/events-and-webhooks.md): the Event log,
  `events.tail`, verifying Deliveries in Rack and Sinatra.
- [Operations and files](docs/guides/operations.md): `Operation#wait`, CSV
  exports and imports, Certificate PDFs.
- [Rails](docs/guides/rails.md): an initializer, a webhook controller and
  jobs.
- [Testing](docs/guides/testing.md): the Sandbox, a fake transport, signing
  your own Deliveries.
- [Versions and upgrades](docs/guides/upgrading.md): what a version number
  promises and how API additions reach you.

Every method, with its HTTP request, Scopes and parameters, is listed in the
[resource reference](docs/reference/resources.md). YARD builds the
[API reference](https://teachmehipaa.github.io/teachmehipaa-ruby/) from the
doc comments, and RBS signatures ship in `sig/`. [`examples/`](examples)
holds small programs you can run against the Sandbox, and
[`docs/`](docs/README.md) indexes it all.

## Development

```sh
bundle install
bundle exec rake          # RuboCop, RBS validation, and the tests under RBS checks
bundle exec rake generate # rebuild resources, models and reference from openapi/sdk-ir.json
```

[CONTRIBUTING.md](CONTRIBUTING.md) covers the generator, the contract suite
and releases.

## Support and security

<!-- TODO(Nick): confirm the support address before launch. -->

For help, contact TeachMeHIPAA support with the `request_id` from the error
or from `last_response`. To report a vulnerability, follow
[SECURITY.md](SECURITY.md) and keep it out of public issues.

## License

MIT. See [LICENSE](LICENSE).
