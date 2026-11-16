# Errors and retries

When a call fails, the client first retries whatever is safe to retry. If
it still can't succeed, it raises a subclass of `TeachMeHipaa::Error`, which
is a `StandardError`, so a bare `rescue => e` catches it too. The samples
assume a `client` built as in the [README](../../README.md#usage).

## Rescuing

Rescue the narrowest class you can act on and let `TeachMeHipaa::Error`
take the rest:

<!-- sample: errors -->
```ruby
begin
  client.learners.retrieve("sub_01JD80AB2C3D4E5F6G7H8J9K0M")
rescue TeachMeHipaa::NotFoundError
  puts "No such Learner"
rescue TeachMeHipaa::PermissionDeniedError => e
  puts "Missing a Scope: #{e.detail}"
rescue TeachMeHipaa::Error => e
  puts "#{e.code}: #{e.detail} (request #{e.request_id})"
  e.errors.each { |field| puts "#{field.path}: #{field.message}" }
end
```

The HTTP status picks the class:

| Class | Raised for |
| --- | --- |
| `InvalidRequestError` | 400, 405, 406, 415 and 422 |
| `IdempotencyError` | 422 `idempotency_key_reuse` (a subclass of `InvalidRequestError`) |
| `AuthenticationError` | 401, or a credential-less client calling a method that needs a token |
| `PermissionDeniedError` | 403, such as a missing Scope |
| `NotFoundError` | 404 |
| `ConflictError` | 409 |
| `PreconditionFailedError` | 412 for a stale ETag, 428 for a missing `if_match:` |
| `RateLimitError` | 429; `retry_after` holds the seconds the API asked for |
| `APIError` | 5xx, or a body that isn't JSON, such as an HTML error page |
| `APIConnectionError` | no response arrived |
| `APITimeoutError` | no response within `timeout` (a subclass of `APIConnectionError`) |
| `OAuthError` | the token endpoint refused your credentials |
| `OperationFailedError` | an Operation you waited on finished with an error |
| `OperationTimeoutError` | an Operation wasn't done within `wait`'s `timeout` |
| `WebhookSignatureError` | a webhook Delivery failed verification |

## What an error knows

API errors carry the API's problem response (RFC 9457):

| Reader | Value |
| --- | --- |
| `code` | a machine-readable String, such as `"seat_unavailable"` |
| `title`, `detail` | a summary and a sentence for humans |
| `errors` | `FieldError`s, each with a `path` and a `message` |
| `status` | the HTTP status |
| `request_id` | the id to give TeachMeHIPAA support |
| `headers` | the response headers, names in lower case |

One status can mean several things, so `case` on `code` when you care which.
The API adds codes over time; re-raise the ones you don't recognise:

<!-- sample: error-codes -->
```ruby
begin
  client.learners.create(email: "ana@example.com", external_id: "hr-123", seat_policy: "require_available")
rescue TeachMeHipaa::ConflictError => e
  case e.code
  when "seat_unavailable" then puts "No free Seat; ask an admin to add Seats"
  when "external_id_conflict" then puts "hr-123 already belongs to another Learner"
  else raise
  end
end
```

`e.message` ends with the request id, so a plain `logger.error(e.message)`
already gives support what it needs.

## Request ids

Every response has an `x-request-id`. You find it as `request_id` on an
error and as `last_response.request_id` on anything a call returns. To tie
the API's records to your own, send your id along:

<!-- sample: request-id -->
```ruby
page = client.learners.list(request_options: { request_id: "hr-sync-42" })
puts page.last_response.request_id
```

The API keeps an id that matches `/\A[A-Za-z0-9._-]{1,128}\z/` and swaps
anything else for one of its own.

## What gets retried

The client retries a call after:

- a network error or timeout (`APIConnectionError`);
- a 409 with code `conflict`, meaning the same idempotency key is still in
  flight;
- a 429, honouring `Retry-After` up to 60 seconds;
- any 5xx.

Between attempts it backs off exponentially, from 0.5 seconds up to 5, with
jitter. It stops after `max_retries` retries, 2 unless you say otherwise.

Only calls that are safe to replay get retried: reads, writes that carry an
`Idempotency-Key`, and writes that are idempotent anyway, such as
`learners.create_launch_link`. Updates (PATCH) and deletes never are. The
[resource reference](../reference/resources.md) marks each method.

Set the budget per client, or per call:

<!-- sample: max-retries -->
```ruby
patient = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  max_retries: 4,
)
puts patient.max_retries

summary = client.compliance.retrieve(request_options: { max_retries: 0 })
puts summary.compliant_rate
```

If you handle rate limits yourself, `RateLimitError#retry_after` holds the
seconds the API asked you to wait.

## Idempotency

Creates and custom methods (`enrollments.cancel`, `learners.export` and the
like) send an `Idempotency-Key`. The client makes a UUID per call and sends
the same one on each retry of that call, so a retried create never enrolls
anyone twice.

A job that might run twice, such as a nightly sync, needs a key that
survives between processes. Pass your own, and the API applies a repeat with
the same key only once:

<!-- sample: request-options -->
```ruby
enrollment = client.enrollments.create(
  email: "ana@example.com",
  course_id: "hipaa-2026",
  request_options: {
    idempotency_key: "hr-sync-2026-11-15-ana",
    max_retries: 5,
    timeout: 10,
    request_id: "hr-sync-42",
  },
)
puts enrollment.enrollment_id, enrollment.last_response.request_id
```

Sending a used key with a different request raises `IdempotencyError`. For
Learners, `learners.upsert_by_external_id` often saves you the bookkeeping:
your External ID already makes it idempotent. The
[roster sync example](../../examples/sync_roster.rb) leans on it.

## Timeouts

`timeout:` defaults to 80 seconds and bounds the connect and each read and
write. A call that keeps timing out raises `APITimeoutError` once its
retries are spent. [Setting up a client](client.md#timeouts) shows how to
tighten it.
