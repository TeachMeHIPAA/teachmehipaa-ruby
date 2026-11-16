# Rails

The gem has no Railtie and needs none. A Rails app uses it like any other
Ruby code: one client built at boot, shared by controllers and jobs, and a
plain controller for webhooks. `Bundler.require` loads the gem when the app
boots, so app code never needs `require "teachmehipaa"`.

## Credentials

Keep the API client's id and secret, and the Signing secret of your Webhook
subscription, in Rails' encrypted credentials (`bin/rails credentials:edit`):

```yaml
teachmehipaa:
  client_id: cli_...
  client_secret: tmh_cs_...
  webhook_secret: ...
```

Use a Sandbox API client in development and staging, and a Live one in
production, each in its own environment's credentials file.

## An initializer

<!-- sample: initializer -->
```ruby
# config/initializers/teachmehipaa.rb
TEACHMEHIPAA = TeachMeHipaa::Client.new(
  client_id: Rails.application.credentials.dig(:teachmehipaa, :client_id),
  client_secret: Rails.application.credentials.dig(:teachmehipaa, :client_secret),
  environment: Rails.env.production? ? :live : :sandbox,
  logger: Rails.logger,
  app_info: { name: "acme-hr" },
)
```

`Client.new` makes no request, so boot stays fast and works offline. The
first API call fetches the token. If both credentials come back `nil`, as
they can during `assets:precompile` on a build server, you get a client that
can make only the public calls, and boot carries on. If only one of the pair
is set, `Client.new` raises `ArgumentError` and the app refuses to boot.

One client serves every Puma thread and every job: it guards its token cache
with a `Mutex`. With `logger: Rails.logger`, each HTTP exchange becomes one
`info` line in your app's log, without bodies or headers.

## Calling the API from a job

Learner writes belong in a background job, where a slow or failed call
doesn't hold up a web request:

<!-- sample: job -->
```ruby
# app/jobs/enroll_employee_job.rb
class EnrollEmployeeJob < ApplicationJob
  retry_on TeachMeHipaa::RateLimitError, wait: 1.minute, attempts: 5

  def perform(external_id, email, name)
    learner = TEACHMEHIPAA.learners.upsert_by_external_id(external_id, email:, name:)
    Rails.logger.info("TeachMeHIPAA Learner #{learner.learner_id} #{learner.created? ? "invited" : "already enrolled"}")
  end
end
```

The client has already retried a 429 up to `max_retries` times before
`RateLimitError` reaches the job; `retry_on` then reschedules the job a
minute later. `upsert_by_external_id` keys on your own External ID: the
first call creates and invites the Learner, and a job that runs again gets
the same Learner back without using a second Seat.

## A webhook endpoint

Point a route at an `ActionController::API` controller:

<!-- sample: routes -->
```ruby
# config/routes.rb
post "/webhooks/teachmehipaa", to: "teachmehipaa_webhooks#create"
```

<!-- sample: webhook-controller -->
```ruby
# app/controllers/teachmehipaa_webhooks_controller.rb
class TeachmehipaaWebhooksController < ActionController::API
  def create
    event = TeachMeHipaa::Webhook.construct_event(
      request.raw_post,
      request.headers,
      Rails.application.credentials.dig(:teachmehipaa, :webhook_secret),
      request.fullpath,
    )
    CertifiedLearnerJob.perform_later(event.data.learner_id) if event.is_a?(TeachMeHipaa::EventLearnerCertified)
    head :ok
  rescue TeachMeHipaa::WebhookSignatureError => e
    render plain: e.code, status: :bad_request
  end
end
```

The controller leans on three things Rails hands it:

- `request.raw_post` is the body byte for byte. `params` has been through a
  JSON parser and won't verify.
- `request.fullpath` keeps the query string, which the signature covers.
- `request.headers` works as is: `construct_event` reads Rack-style names
  such as `HTTP_X_TMH_SIGNATURE`.

`ActionController::API` skips CSRF protection. In a controller that inherits
from `ActionController::Base`, add `skip_forgery_protection`: the signature
is what proves the request came from TeachMeHIPAA.

The controller answers 200 at once and leaves the work to a job, since
TeachMeHIPAA retries any Delivery that doesn't get a 2xx. A Test
delivery arrives as a `TeachMeHipaa::TestDelivery`, falls through the `if`,
and gets its 200 too. [Events and webhooks](events-and-webhooks.md) covers
the Event classes and the error codes in `e.code`.

## Testing the endpoint

`Webhook.generate_test_headers` signs a payload the way TeachMeHIPAA does,
and an integration test can post it straight to the route:

<!-- sample: integration-test -->
```ruby
# test/integration/teachmehipaa_webhooks_test.rb
class TeachmehipaaWebhooksTest < ActionDispatch::IntegrationTest
  test "accepts a signed Test delivery" do
    payload = JSON.generate("test" => true, "subscriptionId" => "whs_01JD8D")
    headers = TeachMeHipaa::Webhook.generate_test_headers(
      payload:,
      secret: Rails.application.credentials.dig(:teachmehipaa, :webhook_secret),
      path: "/webhooks/teachmehipaa",
    )

    post "/webhooks/teachmehipaa", params: payload, headers: headers

    assert_response :ok
  end
end
```

For code that calls the API, build the client your tests use with a fake
transport; [Testing](testing.md#a-fake-transport) shows one.
