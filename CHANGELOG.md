# Changelog

All notable changes to this library are documented here. It follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[semantic versioning](https://semver.org/).

## [1.0.0] - Unreleased

The first release, to ship when the Developer API launches. Generated from
the Developer API document release `waggish-wombat`.

### Added

- `TeachMeHipaa::Client`, covering all 56 Developer API operations as
  resources and models generated from the shared SDK IR: Learners,
  Enrollments, Certificates, Certificate verifications, Compliance, Courses,
  Members, Seats, Seat orders, the payment method, Audit events, Webhook
  subscriptions, the Event log, Operations, `auth.introspect` and Partners.
- Client credentials authentication with cached, single-flight Access tokens
  renewed 60 s before expiry, and one renewal and replay on a 401.
- Live and Sandbox Environments, a `base_url:` override, narrower `scopes:`,
  and `TokenProviders::Static` for Access tokens obtained elsewhere.
- A client without credentials for the public methods (the course catalog
  and Certificate verification), which never send an Access token; other
  calls on it raise `AuthenticationError` before sending.
- The Organization binding: discovered once through `auth.introspect`, or
  given as `organization_id:`.
- Typed errors under `TeachMeHipaa::Error` by status (`InvalidRequestError`,
  `IdempotencyError`, `AuthenticationError`, `PermissionDeniedError`,
  `NotFoundError`, `ConflictError`, `PreconditionFailedError`,
  `RateLimitError`, `APIError`, `APIConnectionError`, `APITimeoutError`),
  plus `OAuthError`, `OperationFailedError`, `OperationTimeoutError` and
  `WebhookSignatureError`, carrying the problem `code`, `detail`, field
  `errors`, `headers` and `request_id`, with a guard that raises `APIError`
  for non-JSON responses instead of a parse error.
- Retries with exponential backoff and jitter for network errors, 409
  `conflict`, 429 and 5xx, honoring `Retry-After`, only for calls that are
  safe to replay; a generated `Idempotency-Key` per create and custom method,
  reused across retries; per-call `request_options:` (`idempotency_key`,
  `max_retries`, `timeout`, `request_id`, `headers`).
- `last_response` on every returned object, with status, headers, request id
  and ETag.
- `TeachMeHipaa::Page`, `Enumerable` over its items, with `next_page?`,
  `next_page`, `each_page` and `auto_paging_each` across every page.
- Conditional writes and reads with ETags (`if_match:` takes an ETag or the
  object read; `if_none_match:` returns `NotModified` on 304), and
  merge-patch updates that tell an omitted keyword from one set to `nil`.
- `Operation#wait` and `Operation#export_result` for export CSVs; Test
  delivery and redrive results typed by `tag`, with
  `WebhookDeliveryResult::Unknown` for tags added later.
- Enrollment CSV imports from a path, an IO or a `FilePart`, and Certificate
  PDF downloads as a `BinaryResponse` or streamed to a block.
- `Webhook.construct_event`, which verifies a Delivery's signature, body
  hash, path and timestamp and returns a typed Event, `UnknownEvent` or
  `TestDelivery`, accepting a Hash, a Rack env or Rails' `request.headers`;
  and `Webhook.generate_test_headers` for testing handlers.
- `events.tail` to read the Event log from a saved position, once or
  following new Events, stoppable with a `stop:` callable.
- Opt-in logging to a `logger:`, one line per HTTP exchange with method,
  path, status, latency and request id, never bodies, headers or
  credentials; a `User-Agent` with your `app_info:`; and a pluggable
  `transport:`.
- RBS signatures for every public class and method. Ruby 3.2 or newer, no
  runtime dependencies, no telemetry and no disk writes.
