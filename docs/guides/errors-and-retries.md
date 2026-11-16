# Errors and retries

A failed call raises a subclass of `TeachMeHipaa::Error`, after the client has
retried whatever was safe to retry. This guide covers the error classes, how
to branch on them, and how retries and idempotency keys keep a write from
happening twice.

## Error classes

Every error the library raises is a `TeachMeHipaa::Error` (a
`StandardError`), with a subclass chosen by the HTTP status:

| Class | When |
| --- | --- |
| `InvalidRequestError` | 400, 405, 406, 415 and 422 |
| `IdempotencyError` | 422 `idempotency_key_reuse` (an `InvalidRequestError`) |
| `AuthenticationError` | 401, or a client without credentials calling a method that needs them |
| `PermissionDeniedError` | 403, such as a missing Scope |
| `NotFoundError` | 404 |
| `ConflictError` | 409 |
| `PreconditionFailedError` | 412 (stale ETag) and 428 (missing `if_match:`) |
| `RateLimitError` | 429, with `retry_after` in seconds |
| `APIError` | 5xx, or a response that isn't JSON (such as an HTML error page) |
| `APIConnectionError` | No response arrived |
| `APITimeoutError` | No response within `timeout` (an `APIConnectionError`) |
| `OAuthError` | The token endpoint refused to issue an Access token |
| `OperationFailedError` | An Operation you waited on finished with an error |
| `OperationTimeoutError` | An Operation was not done within `wait`'s `timeout` |
| `WebhookSignatureError` | A webhook Delivery failed verification |

Rescue the most specific class you can handle, and `TeachMeHipaa::Error` for
the rest:

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

Samples in the guides assume a `client` created as in [Getting
started](getting-started.md).

## What an error carries

API errors mirror the API's problem response (RFC 9457):

| Reader | Holds |
| --- | --- |
| `code` | A machine-readable code, such as `"seat_unavailable"` |
| `title`, `detail` | A summary and a human-readable explanation |
| `errors` | Field-level problems, each a `FieldError` with `path` and `message` |
| `status` | The HTTP status |
| `request_id` | The id to quote to TeachMeHIPAA support |
| `headers` | The response headers, with lower-case names |

Branch on `code` when one status covers several situations. New codes can
appear at any time, so always handle codes you don't know:

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

The error's message ends with the request id, so logs of `e.message` carry
it too.

## Request ids

Every response carries an `x-request-id`, which TeachMeHIPAA support can look
up. It is on every error as `request_id`, and on every returned object as
`last_response.request_id`. To correlate the API's records with your own,
send your id with the call:

<!-- sample: request-id -->
```ruby
page = client.learners.list(request_options: { request_id: "hr-sync-42" })
puts page.last_response.request_id
```

The API keeps a request id that matches `/\A[A-Za-z0-9._-]{1,128}\z/` and
replaces any other with its own.

## Retries

The client retries a call that failed on the way:

- network errors and timeouts (`APIConnectionError`);
- 409 with code `conflict` (the same idempotency key is still in flight);
- 429, honoring `Retry-After` up to 60 seconds;
- 5xx.

It waits between attempts, backing off exponentially from 0.5 seconds up to
5 seconds with jitter, and makes up to `max_retries` retries (2 by default).
Only calls that are safe to replay are retried: reads, writes that carry an
`Idempotency-Key`, and writes that are idempotent by nature, such as
`learners.create_launch_link`. Updates (PATCH) and deletes are never
retried. The [resource reference](../reference/resources.md) says which
methods retry.

Change the budget for the client with `max_retries:`, or for one call:

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

`RateLimitError#retry_after` says how long the API asked you to wait, if you
handle rate limits yourself.

## Idempotency

Every create and custom method (such as `enrollments.cancel` or
`learners.export`) sends an `Idempotency-Key`. The client generates a UUID
for each call and reuses it for each of that call's retries, so a retry
never enrolls a Learner twice.

To make a write safe to repeat across processes, such as a nightly job that
may run twice, pass your own key; the API doesn't apply a repeat of the call
with the same key twice:

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

Reusing a key with a different request raises `IdempotencyError`. For
Learners, `learners.upsert_by_external_id` is often simpler: it is
idempotent by your own External ID (see [the roster sync
example](../../examples/sync_roster.rb)).

## Timeouts

`timeout:` (80 seconds by default) bounds connecting and each read and write.
A call that times out raises `APITimeoutError` once its retries are spent.
Set it for the client or per call; see [Configuration](configuration.md).
