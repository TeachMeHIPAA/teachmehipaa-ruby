# Testing

Test your integration at two levels. End-to-end checks run against the
Sandbox. Unit tests run against a fake transport and never open a socket.
Live credentials belong in neither.

## The Sandbox

The Sandbox is its own Environment, with its own API clients and
Organizations. Its credentials fail against Live, so a suite that holds only
Sandbox credentials can't touch production data. Check where a token
belongs with `auth.introspect`:

<!-- sample: sandbox -->
```ruby
sandbox = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  environment: :sandbox,
)
puts sandbox.auth.introspect.mode
```

A Sandbox token's `mode` is `"test"`.

## A fake transport

Every request goes through the client's `transport:`. Swap in your own
object and the rest of the client runs for real: parameters, errors, pages
and retries all behave as they would against the API.

A transport answers `call(request)`. The request is a
`TeachMeHipaa::Transport::Request` with `http_method`, `url`, `headers`,
`body` and `timeout`. The reply is a `TeachMeHipaa::Transport::Response`
with `status`, `headers` (names in lower case) and `body`.

Pair the fake with a `TokenProviders::Static` token and an
`organization_id:`, and it only has to answer the calls your code makes:

<!-- sample: fake-transport -->
```ruby
require "json"

class CannedTransport
  attr_reader :requests

  def initialize(replies)
    @replies = replies
    @requests = []
  end

  def call(request)
    @requests << request
    status, body = @replies.fetch([request.http_method, URI(request.url).path])
    TeachMeHipaa::Transport::Response.new(
      status:, headers: { "content-type" => "application/json" }, body: JSON.generate(body),
    )
  end
end

transport = CannedTransport.new(
  ["GET", "/v1/organizations/org_test/compliance"] => [200, { "compliantRate" => 0.75 }],
  ["GET", "/v1/organizations/org_test/learners/sub_missing"] => [404, { "code" => "not_found" }],
)
client = TeachMeHipaa::Client.new(
  token_provider: TeachMeHipaa::TokenProviders::Static.new("test-token"),
  organization_id: "org_test",
  transport:,
  sleep: ->(_seconds) {},
)

puts client.compliance.retrieve.compliant_rate
begin
  client.learners.retrieve("sub_missing")
rescue TeachMeHipaa::NotFoundError => e
  puts e.code
end
puts transport.requests.length
```

A few things to know:

- Paths include the base URL's `/v1`.
- A 4xx or 5xx reply with a problem body raises the matching error class,
  which is how you test your `rescue` branches.
- `sleep:` takes any callable. A lambda that returns at once makes retries
  and `Operation#wait` finish instantly. `clock:` (monotonic seconds) sets
  the time the client sees.

For an HTTP mock server instead, such as Prism serving the OpenAPI document,
pass its URL as `base_url:`.

## Signed Deliveries

`TeachMeHipaa::Webhook.generate_test_headers` returns the headers
TeachMeHIPAA would send with a payload, signed with your Signing secret for
the path you name. Post the payload with them and your handler can't tell
the difference. With the Sinatra app from
[Events and webhooks](events-and-webhooks.md#verifying-a-delivery), turn
the headers into Rack env keys (`HTTP_X_TMH_SIGNATURE` and so on, and
`CONTENT_TYPE`, without which Rack reads the body as a form):

<!-- sample: sign-delivery -->
```ruby
require "json"
require "rack/mock"

payload = JSON.generate("test" => true, "subscriptionId" => "whs_01JD8D")
headers = TeachMeHipaa::Webhook.generate_test_headers(
  payload:, secret: ENV.fetch("TMH_WEBHOOK_SECRET"), path: "/webhooks/tmh",
)
env = headers.to_h { |name, value| ["HTTP_#{name.upcase.tr("-", "_")}", value] }
env["CONTENT_TYPE"] = env.delete("HTTP_CONTENT_TYPE")

response = Rack::MockRequest.new(TmhWebhooks).post("/webhooks/tmh", env.merge(input: payload))
puts response.status, response.body
```

To check the unhappy paths, sign for a different path or edit the payload
after signing, and expect a 400. `timestamp:` signs a Delivery from the past,
for testing the 5-minute tolerance. In Rails, an integration test can post
the headers as they are; [Rails](rails.md#testing-the-endpoint) has one.
