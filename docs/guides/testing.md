# Testing

Test your integration at two levels: end to end against the Sandbox
Environment, and in your unit tests against a fake transport that never
touches the network. Neither should ever use Live credentials.

## The Sandbox

The Sandbox is a separate Environment for building and testing, with its own
API clients and Organizations. Sandbox credentials don't work against Live,
and Live credentials don't work against the Sandbox, so a test suite with
Sandbox credentials can't change production data. Point a client at it with
`environment: :sandbox`, and check which Environment a token belongs to with
`auth.introspect`:

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

The client sends every request through its `transport:`, any object whose
`call(request)` takes a `TeachMeHipaa::Transport::Request` (`http_method`,
`url`, `headers`, `body`, `timeout`) and returns a
`TeachMeHipaa::Transport::Response` (`status`, `headers` with lower-case
names, `body`). Pass a fake one to test your code against canned responses.
Your code then runs through the real client: the same parameters, errors,
pagination and retries.

Use a `TokenProviders::Static` token and an `organization_id:`, so your fake
only has to answer the calls your code makes:

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

Paths include the base URL's `/v1`. A `Response` body of problem JSON with
a 4xx or 5xx status raises the matching error, so you can test your error
handling. Pass `sleep:` a lambda that doesn't wait, so tests of retries and
`Operation#wait` run instantly; `clock:` (monotonic seconds) controls the
time the client sees.

To test against an HTTP mock server instead, such as Prism serving the
OpenAPI document, pass its URL as `base_url:`.

## Sign test Deliveries

`TeachMeHipaa::Webhook.generate_test_headers` returns the headers
TeachMeHIPAA would send with a payload, signed with your Signing secret for
the path you give. Post the payload with those headers to your handler. With
the Sinatra app from the [Webhooks guide](webhooks.md#sinatra-and-rack), the
headers become Rack env keys: `HTTP_X_TMH_SIGNATURE` and so on, and
`CONTENT_TYPE`, without which Rack would read the body as a form:

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

Sign a payload for a different path, or change it after signing, to check
that your handler rejects it with 400. Pass `timestamp:` to sign a Delivery
from the past and test the 5-minute tolerance.
