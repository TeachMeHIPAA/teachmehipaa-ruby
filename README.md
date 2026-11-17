# teachmehipaa

Official Ruby library for the TeachMeHIPAA Developer API.

[![CI](https://github.com/TeachMeHIPAA/teachmehipaa-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/TeachMeHIPAA/teachmehipaa-ruby/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Documentation

**[docs.teachmehipaa.com/api](https://docs.teachmehipaa.com/api?lang=ruby)**
has the API reference with Ruby samples for every operation, plus guides for
authentication, pagination, errors and webhooks.

## Installation

> [!IMPORTANT]
> **Pre-release.** The Developer API isn't generally available yet, and the
> gem isn't on RubyGems. Until both happen, point Bundler at this repository.
> The interface can still change before 1.0.

<!-- sample: install -->
```ruby
gem "teachmehipaa", git: "https://github.com/TeachMeHIPAA/teachmehipaa-ruby"
```

Then run `bundle install`. Once the gem reaches RubyGems,
`gem "teachmehipaa"` replaces the whole line.

## Requirements

Ruby 3.2 or newer. The gem has no runtime dependencies: it talks to the API
through `Net::HTTP` and parses JSON with the standard library.

## Usage

<!-- sample: quickstart -->
```ruby
require "teachmehipaa"

client = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  environment: :sandbox,
)

client.learners.list(status: :in_progress).auto_paging_each do |learner|
  puts learner.email
end
```

The client id (`cli_…`) and secret (`tmh_cs_…`) come from an API client you
create in the TeachMeHIPAA console. Make it in the Sandbox
(`https://sandbox.api.tme.so/v1`) while you build. [`examples/`](examples)
holds more programs to run against it.

## Contributing

```sh
bundle install
bundle exec rake          # RuboCop, RBS validation, and the tests under RBS checks
bundle exec rake generate # rebuild resources, models and code samples from openapi/sdk-ir.json
```

[CONTRIBUTING.md](CONTRIBUTING.md) covers the generator, the contract suite
and releases.

## Support

<!-- TODO(Nick): confirm the support address before launch. -->

For help, contact TeachMeHIPAA support with the `request_id` from the error
or from `last_response`.

## Security

To report a vulnerability, follow [SECURITY.md](SECURITY.md) and keep it out
of public issues.

## License

MIT. See [LICENSE](LICENSE).
