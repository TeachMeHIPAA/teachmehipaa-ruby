<!-- Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`. -->

# Resource reference

Every method under `TeachMeHipaa::Client`, generated from the Developer
API document release `trimmed-2026-11-15`. For what the library adds on top
(`events.tail`, `Operation#wait`, `Webhook`), see the [guides](../README.md);
for every class and field, see the [API reference](https://teachmehipaa.github.io/teachmehipaa-ruby/).

- Ids in the path are positional arguments; everything else is a keyword.
- Paths are relative to the Environment's base URL: `https://api.tme.so/v1` (Live) or
  `https://api-teachmehipaa-dev.web.app/v1` (Sandbox). The client fills in `{orgId}` from
  the Organization binding, so no method takes an Organization id.
- Every method also takes `request_options:`, a Hash of
  `idempotency_key`, `max_retries`, `timeout`, `request_id` and `headers`
  for that call only (see [Configuration](../guides/configuration.md)).
- Types are in YARD notation. Enum fields are Strings and may hold values
  newer than this library.

## Contents

- [Audit events](#audit-events): `list`
- [Auth](#auth): `introspect`
- [Certificate verifications](#certificate-verifications): `retrieve`
- [Certificates](#certificates): `download_pdf`, `export`, `list`, `retrieve`, `retrieve_links`
- [Compliance](#compliance): `retrieve`
- [Courses](#courses): `list`, `retrieve`
- [Enrollments](#enrollments): `batch`, `batch_by_filter`, `cancel`, `create`, `export`, `import`, `list`, `preview_import`, `remind`, `renew`, `resend_invite`, `retrieve`
- [Events](#events): `list`
- [Learners](#learners): `batch_upsert`, `create`, `create_launch_link`, `export`, `list`, `offboard`, `remind`, `retrieve`, `update`, `upsert_by_external_id`
- [Members](#members): `list`, `retrieve`
- [Operations](#operations): `retrieve`
- [Seats](#seats): `retrieve`
- [Webhook subscriptions](#webhook-subscriptions): `create`, `delete`, `list`, `redrive`, `retrieve`, `test`, `update`

## Audit events

`client.audit_events`

### `client.audit_events.list`

**List all audit events.** Returns a list of the organization's audit events, newest first. Filter by `type`, `transition`, `subjectId`, or a `since` and `until` range.

```ruby
client.audit_events.list(limit: nil, cursor: nil, type: nil, transition: nil,
                         subject_id: nil, since: nil, until: nil,
                         request_options: {}) # => Page<AuditEvent>
```

- **HTTP:** `GET /organizations/{orgId}/audit-events`.
- **Scopes:** `audit:read`.
- **Returns:** `Page<AuditEvent>`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `limit:` | `Integer, nil` |  | How many objects to return, between 1 and 100. Defaults to 20. |
| `cursor:` | `String, nil` |  | The `nextCursor` from the previous page. |
| `type:` | `String, Symbol, nil` |  | Filter to one audit-event family. |
| `transition:` | `String, Symbol, nil` |  | Filter to one lifecycle transition. |
| `subject_id:` | `String, nil` |  | Filter to one member (canonical subject id). |
| `since:` | `Time, String, nil` |  | Inclusive lower bound on `at` (ISO-8601 instant). |
| `until:` | `Time, String, nil` |  | Inclusive upper bound on `at` (ISO-8601 instant). |

## Auth

`client.auth`

### `client.auth.introspect`

**Retrieve the current token.** Describes the access token you call with: whether it belongs to an API client or a person, its organization, its scopes and when it expires. Needs no scope.

```ruby
client.auth.introspect(request_options: {}) # => TokenIntrospection
```

- **HTTP:** `GET /auth/introspection`.
- **Scopes:** Any Access token.
- **Returns:** `TokenIntrospection`.
- **Retries:** Retried safely.

Takes no parameters besides `request_options:`.

## Certificate verifications

`client.certificate_verifications`

### `client.certificate_verifications.retrieve`

**Verify a certificate.** Verifies the certificate behind a `https://tme.so/{tinyId}` link. Needs no access token. Limited to 60 requests a minute per IP address.

```ruby
client.certificate_verifications.retrieve(tiny_id,
                                          request_options: {}) # => CertificateVerification
```

- **HTTP:** `GET /certificate-verifications/{tinyId}`.
- **Scopes:** None: a public method that sends no Access token.
- **Returns:** `CertificateVerification`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `tiny_id` | `String` | Yes | The id at the end of the certificate's tme.so link. |

## Certificates

`client.certificates`

### `client.certificates.download_pdf`

**Download a certificate.** Downloads the certificate as a PDF. Revoked and expired certificates are watermarked. Requires the `certificates:read` scope.

```ruby
client.certificates.download_pdf(cert_id,
                                 request_options: {}) # => BinaryResponse
client.certificates.download_pdf(cert_id,
                                 request_options: {}) { |chunk| ... } # => StreamedResponse
```

- **HTTP:** `GET /organizations/{orgId}/certificates/{certId}/content`.
- **Scopes:** `certificates:read`.
- **Returns:** `BinaryResponse, StreamedResponse`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `cert_id` | `String` | Yes |  |

### `client.certificates.export`

**Export certificates.** Exports the organization's certificate records as CSV. Requires the `certificates:read` scope.

```ruby
client.certificates.export(format:, request_options: {}) # => Operation
```

- **HTTP:** `POST /organizations/{orgId}/certificates:export`.
- **Scopes:** `certificates:read`.
- **Returns:** `Operation`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `format:` | `String, Symbol` | Yes | The file format. Only `csv` today. |

### `client.certificates.list`

**List all certificates.** Returns a list of the organization's certificates. Pass `subjectId` to list one learner's.

```ruby
client.certificates.list(limit: nil, cursor: nil, subject_id: nil,
                         request_options: {}) # => Page<Certificate>
```

- **HTTP:** `GET /organizations/{orgId}/certificates`.
- **Scopes:** `certificates:read`.
- **Returns:** `Page<Certificate>`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `limit:` | `Integer, nil` |  | How many objects to return, between 1 and 100. Defaults to 20. |
| `cursor:` | `String, nil` |  | The `nextCursor` from the previous page. |
| `subject_id:` | `String, nil` |  | Filter to one holder (canonical subject id). |

### `client.certificates.retrieve`

**Retrieve a certificate.** Retrieves a certificate.

```ruby
client.certificates.retrieve(cert_id, request_options: {}) # => Certificate
```

- **HTTP:** `GET /organizations/{orgId}/certificates/{certId}`.
- **Scopes:** `certificates:read`.
- **Returns:** `Certificate`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `cert_id` | `String` | Yes |  |

### `client.certificates.retrieve_links`

**Retrieve certificate links.** Retrieves the certificate's LinkedIn add-to-profile link and its public `tme.so` verification link. Requires the `certificates:read` scope.

```ruby
client.certificates.retrieve_links(cert_id,
                                   request_options: {}) # => CertificateLinks
```

- **HTTP:** `GET /organizations/{orgId}/certificates/{certId}/credentials`.
- **Scopes:** `certificates:read`.
- **Returns:** `CertificateLinks`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `cert_id` | `String` | Yes |  |

## Compliance

`client.compliance`

### `client.compliance.retrieve`

**Retrieve the compliance summary.** Counts the organization's learners in one course by status. Removed learners aren't counted.

```ruby
client.compliance.retrieve(course_id: nil,
                           request_options: {}) # => ComplianceSummary
```

- **HTTP:** `GET /organizations/{orgId}/compliance`.
- **Scopes:** `compliance:read`.
- **Returns:** `ComplianceSummary`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `course_id:` | `String, nil` |  | The course. Defaults to the organization's default course. |

## Courses

`client.courses`

### `client.courses.list`

**List all courses.** Returns a list of the courses in the public catalog. Needs no access token.

```ruby
client.courses.list(limit: nil, cursor: nil,
                    request_options: {}) # => Page<Course>
```

- **HTTP:** `GET /courses`.
- **Scopes:** None: a public method that sends no Access token.
- **Returns:** `Page<Course>`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `limit:` | `Integer, nil` |  | How many objects to return, between 1 and 100. Defaults to 20. |
| `cursor:` | `String, nil` |  | The `nextCursor` from the previous page. |

### `client.courses.retrieve`

**Retrieve a course.** Retrieves a course from the public catalog.

```ruby
client.courses.retrieve(course_id, if_none_match: nil,
                        request_options: {}) # => Course
```

- **HTTP:** `GET /courses/{courseId}`.
- **Scopes:** None: a public method that sends no Access token.
- **Returns:** `Course, NotModified`.
- **Retries:** Retried safely.
- **If-None-Match:** `if_none_match:` returns `NotModified` when your copy is current.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `course_id` | `String` | Yes |  |
| `if_none_match:` | `String, Model` |  | The ETag of the copy you hold: a String, or the object you read. |

## Enrollments

`client.enrollments`

### `client.enrollments.batch`

**Update many enrollments.** Reminds, resends, cancels, renews, archives or unarchives up to 500 enrollments in one request, chosen by id or by filter. Each enrollment succeeds or fails on its own. Requires the `enrollments:write` scope.

```ruby
client.enrollments.batch(operation:, select:,
                         request_options: {}) # => EnrollmentsBatchResults
```

- **HTTP:** `POST /organizations/{orgId}/enrollments:batch`.
- **Scopes:** `enrollments:write`.
- **Returns:** `EnrollmentsBatchResults`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `operation:` | `String, Symbol` | Yes | What to do to each enrollment: `remind`, `resendInvite`, `cancel`, `recertify`, `archive` or `unarchive`. |
| `select:` | `Hash` | Yes | The enrollments to act on: a list of `enrollmentIds` (up to 500), or a `filter`. |

### `client.enrollments.batch_by_filter`

**Update many enrollments.** Reminds, resends, cancels, renews, archives or unarchives up to 500 enrollments in one request, chosen by id or by filter. Each enrollment succeeds or fails on its own. Requires the `enrollments:write` scope.

```ruby
client.enrollments.batch_by_filter(operation:, select:,
                                   request_options: {}) # => Operation
```

- **HTTP:** `POST /organizations/{orgId}/enrollments:batch`.
- **Scopes:** `enrollments:write`.
- **Returns:** `Operation`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `operation:` | `String, Symbol` | Yes | What to do to each enrollment: `remind`, `resendInvite`, `cancel`, `recertify`, `archive` or `unarchive`. |
| `select:` | `Hash` | Yes | The enrollments to act on: a list of `enrollmentIds` (up to 500), or a `filter`. |

### `client.enrollments.cancel`

**Cancel an enrollment.** Cancels an invite that hasn't been accepted yet and returns its seat to the pool. With `refund: true`, refunds the seat to the card that paid for it instead. The enrollment remains, with status `CANCELLED`. Requires the `enrollments:write` scope.

```ruby
client.enrollments.cancel(enrollment_id, refund: nil,
                          request_options: {}) # => CancelEnrollmentResponse
```

- **HTTP:** `POST /organizations/{orgId}/enrollments/{enrollmentId}:cancel`.
- **Scopes:** `enrollments:write`.
- **Returns:** `CancelEnrollmentResponse`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `enrollment_id` | `String` | Yes |  |
| `refund:` | `Boolean, nil` |  | Refund the seat to the card that paid for it instead of returning it to the pool. Defaults to `false`. |

### `client.enrollments.create`

**Create an enrollment.** Invites a person to a course, creating their profile if needed, and uses one seat. The course defaults to `hipaa`. Requires the `enrollments:write` scope.

```ruby
client.enrollments.create(email:, name: nil, course_id: nil,
                          request_options: {}) # => Enrollment
```

- **HTTP:** `POST /organizations/{orgId}/enrollments`.
- **Scopes:** `enrollments:write`.
- **Returns:** `Enrollment`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `email:` | `String` | Yes | The learner's email address. |
| `name:` | `String, nil` |  | The learner's full name. |
| `course_id:` | `String, nil` |  | The course to invite them to. Defaults to `hipaa`. |

### `client.enrollments.export`

**Export enrollments.** Exports the organization's enrollments as CSV. Requires the `enrollments:read` scope.

```ruby
client.enrollments.export(format:, request_options: {}) # => Operation
```

- **HTTP:** `POST /organizations/{orgId}/enrollments:export`.
- **Scopes:** `enrollments:read`.
- **Returns:** `Operation`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `format:` | `String, Symbol` | Yes | The file format. Only `csv` today. |

### `client.enrollments.import`

**Import learners from CSV.** Invites everyone in a CSV file with an `email` column (and optional `name` and `courseId`). Send `validateOnly: true` first to preview the file without inviting anyone. Up to 500 rows. Requires the `enrollments:write` scope.

```ruby
client.enrollments.import(file:, options: nil,
                          request_options: {}) # => Operation
```

- **HTTP:** `POST /organizations/{orgId}/enrollments:import`.
- **Scopes:** `enrollments:write`.
- **Returns:** `Operation`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `file:` | `String, Pathname, IO, FilePart` | Yes | UTF-8 CSV (RFC 4180: quoted fields, `""` escapes, CRLF/LF). Header row required. |
| `options:` | `Hash, nil` |  |  |

### `client.enrollments.list`

**List all enrollments.** Returns a list of the organization's enrollments. Filter by `status`, `courseId` or `archived`. Requires the `enrollments:read` scope.

```ruby
client.enrollments.list(limit: nil, cursor: nil, status: nil, course_id: nil,
                        archived: nil, include: nil,
                        request_options: {}) # => Page<OrgEnrollmentListItem>
```

- **HTTP:** `GET /organizations/{orgId}/enrollments`.
- **Scopes:** `enrollments:read`.
- **Returns:** `Page<OrgEnrollmentListItem>`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `limit:` | `Integer, nil` |  | How many objects to return, between 1 and 1000. Defaults to 20. |
| `cursor:` | `String, nil` |  | The `nextCursor` from the previous page. |
| `status:` | `String, Symbol, nil` |  | Filter on the derived effectiveStatus. |
| `course_id:` | `String, nil` |  |  |
| `archived:` | `String, Symbol, nil` |  |  |
| `include:` | `String, Symbol, nil` |  | Opt-in enrichment. With `priorCertificate`, an item carries `priorCertificate` (object, or null when the server confirmed there is none). The key is omitted on an item whose answer is unknown, and on every item of the page if the certificate lookup failed; clients must treat a missing key as unknown, never as null. |

### `client.enrollments.preview_import`

**Import learners from CSV.** Invites everyone in a CSV file with an `email` column (and optional `name` and `courseId`). Send `validateOnly: true` first to preview the file without inviting anyone. Up to 500 rows. Requires the `enrollments:write` scope.

```ruby
client.enrollments.preview_import(file:, options: nil,
                                  request_options: {}) # => ImportPreview
```

- **HTTP:** `POST /organizations/{orgId}/enrollments:import`.
- **Scopes:** `enrollments:write`.
- **Returns:** `ImportPreview`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `file:` | `String, Pathname, IO, FilePart` | Yes | UTF-8 CSV (RFC 4180: quoted fields, `""` escapes, CRLF/LF). Header row required. |
| `options:` | `Hash, nil` |  |  |

### `client.enrollments.remind`

**Remind an enrollment.** Emails the learner again: the invitation if they haven't joined, or a reminder linking to the training if they have. Requires the `enrollments:write` scope.

```ruby
client.enrollments.remind(enrollment_id,
                          request_options: {}) # => EnrollmentActionAccepted
```

- **HTTP:** `POST /organizations/{orgId}/enrollments/{enrollmentId}:remind`.
- **Scopes:** `enrollments:write`.
- **Returns:** `EnrollmentActionAccepted`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `enrollment_id` | `String` | Yes |  |

### `client.enrollments.renew`

**Renew an enrollment.** Starts the next certification cycle for a certified learner and invites them again, using one seat. Retrying never uses a second seat. Requires the `enrollments:write` scope.

```ruby
client.enrollments.renew(enrollment_id, request_options: {}) # => Enrollment
```

- **HTTP:** `POST /organizations/{orgId}/enrollments/{enrollmentId}:renew`.
- **Scopes:** `enrollments:write`.
- **Returns:** `Enrollment`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `enrollment_id` | `String` | Yes |  |

### `client.enrollments.resend_invite`

**Resend an invite.** Sends a pending invite again, within the same cycle. To invite a certified learner again, renew the enrollment. Requires the `enrollments:write` scope.

```ruby
client.enrollments.resend_invite(enrollment_id,
                                 request_options: {}) # => EnrollmentActionAccepted
```

- **HTTP:** `POST /organizations/{orgId}/enrollments/{enrollmentId}:resendInvite`.
- **Scopes:** `enrollments:write`.
- **Returns:** `EnrollmentActionAccepted`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `enrollment_id` | `String` | Yes |  |

### `client.enrollments.retrieve`

**Retrieve an enrollment.** Retrieves an enrollment. Requires the `enrollments:read` scope.

```ruby
client.enrollments.retrieve(enrollment_id, if_none_match: nil,
                            request_options: {}) # => Enrollment
```

- **HTTP:** `GET /organizations/{orgId}/enrollments/{enrollmentId}`.
- **Scopes:** `enrollments:read`.
- **Returns:** `Enrollment, NotModified`.
- **Retries:** Retried safely.
- **If-None-Match:** `if_none_match:` returns `NotModified` when your copy is current.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `enrollment_id` | `String` | Yes |  |
| `if_none_match:` | `String, Model` |  | The ETag of the copy you hold: a String, or the object you read. |

## Events

`client.events`

### `client.events.list`

**List all events.** Returns a list of the organization's events from the last 30 days, oldest first. Pass the last `eventId` you processed as `after` to resume where you stopped, and `type` to list one event type.

```ruby
client.events.list(limit: nil, after: nil, type: nil,
                   request_options: {}) # => Page<Event>
```

- **HTTP:** `GET /organizations/{orgId}/events`.
- **Scopes:** `webhooks:manage` or `audit:read`.
- **Returns:** `Page<Event>`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `limit:` | `Integer, nil` |  | How many objects to return, between 1 and 100. Defaults to 20. |
| `after:` | `String, nil` |  | Return events after this event id (exclusive). The previous page's `nextCursor`. |
| `type:` | `String, Symbol, nil` |  | Filter to one event type. |

## Learners

`client.learners`

### `client.learners.batch_upsert`

**Create many learners.** Creates or retrieves up to 500 learners in one request. Each item works like creating one learner and succeeds or fails on its own.

```ruby
client.learners.batch_upsert(items:, delivery: nil, seat_policy: nil,
                             request_options: {}) # => Operation
```

- **HTTP:** `POST /organizations/{orgId}/learners:batchUpsert`.
- **Scopes:** `learners:write`.
- **Returns:** `Operation`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `items:` | `Array<Hash>` | Yes | Up to 500 learners, each with the same fields as creating one learner. |
| `delivery:` | `String, Symbol, nil` |  | Applies to every item. `email` (default) sends invites; `none` sends nothing. |
| `seat_policy:` | `String, Symbol, nil` |  | Applies to every item. `require_available` fails an item when no seat is free. |

### `client.learners.create`

**Create a learner.** Adds a person to the organization and invites them to a course in one call, using one seat. If the email or `externalId` already belongs to an active learner in the course, nothing is created. With `delivery: "none"`, no email is sent and the response includes a `joinUrl` for you to deliver.

```ruby
client.learners.create(email:, name: nil, external_id: nil, course_id: nil,
                       delivery: nil, seat_policy: nil,
                       request_options: {}) # => LearnerWriteResult
```

- **HTTP:** `POST /organizations/{orgId}/learners`.
- **Scopes:** `learners:write`.
- **Returns:** `LearnerWriteResult`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `email:` | `String` | Yes | The learner's email address. |
| `name:` | `String, nil` |  | The learner's full name. |
| `external_id:` | `String, nil` |  | Your own id for the learner, unique within the organization. |
| `course_id:` | `String, nil` |  | The course to invite them to. Defaults to the organization's default course. |
| `delivery:` | `String, Symbol, nil` |  | `email` (default) sends the invite email. `none` sends nothing and returns `joinUrl` for you to deliver. |
| `seat_policy:` | `String, Symbol, nil` |  | `require_available` fails with `409` when no seat is free. |

### `client.learners.create_launch_link`

**Create a launch link.** Creates a link that opens the course with the learner already signed in, for a "Start training" button in your product. The link works once and expires after 5 minutes: create it when the learner clicks, then redirect them to it. Never email, store or log it. Only for a learner who has accepted their invite.

```ruby
client.learners.create_launch_link(learner_id, course_id: nil,
                                   request_options: {}) # => LearnerLaunchLink
```

- **HTTP:** `POST /organizations/{orgId}/learners/{learnerId}:createLaunchLink`.
- **Scopes:** `learners:write`.
- **Returns:** `LearnerLaunchLink`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `learner_id` | `String` | Yes | The learner's canonical subject id (sub_… ULID). |
| `course_id:` | `String, nil` |  | The course. Defaults to the organization's default course. |

### `client.learners.export`

**Export learners.** Exports the organization's learners in one course as CSV, optionally only those with one `status`. Requires the `learners:read` scope.

```ruby
client.learners.export(format:, course_id: nil, status: nil,
                       request_options: {}) # => Operation
```

- **HTTP:** `POST /organizations/{orgId}/learners:export`.
- **Scopes:** `learners:read`.
- **Returns:** `Operation`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `format:` | `String, Symbol` | Yes | The file format. Only `csv` today. |
| `course_id:` | `String, nil` |  | The course to export. Defaults to the organization's default course. |
| `status:` | `String, Symbol, nil` |  | Only export learners with this status. |

### `client.learners.list`

**List all learners.** Returns a list of the organization's learners in one course, with each learner's status, dates and current certificate. Filter by `status`, or find one learner by `email` or `externalId`.

```ruby
client.learners.list(limit: nil, cursor: nil, email: nil, external_id: nil,
                     status: nil, course_id: nil,
                     request_options: {}) # => Page<Learner>
```

- **HTTP:** `GET /organizations/{orgId}/learners`.
- **Scopes:** `learners:read`.
- **Returns:** `Page<Learner>`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `limit:` | `Integer, nil` |  | How many objects to return, between 1 and 100. Defaults to 20. |
| `cursor:` | `String, nil` |  | The `nextCursor` from the previous page. |
| `email:` | `String, nil` |  |  |
| `external_id:` | `String, nil` |  | The integration's own id for the learner (unique per organization), or the SCIM `externalId` when none was set. |
| `status:` | `String, Symbol, nil` |  |  |
| `course_id:` | `String, nil` |  | The course. Defaults to the organization's default course. |

### `client.learners.offboard`

**Offboard a learner.** Removes a learner from the organization. A learner who hasn't started has their invite cancelled and the seat returned; a learner who has started keeps their training history and certificates. Releases the learner's `externalId`.

```ruby
client.learners.offboard(learner_id, if_match: nil, course_id: nil,
                         request_options: {}) # => Learner
```

- **HTTP:** `POST /organizations/{orgId}/learners/{learnerId}:offboard`.
- **Scopes:** `learners:write`.
- **Returns:** `Learner`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.
- **If-Match:** Optional: `if_match:` takes the ETag or the object you read; a stale one raises `PreconditionFailedError`.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `learner_id` | `String` | Yes | The learner's canonical subject id (sub_… ULID). |
| `if_match:` | `String, Model` |  | The ETag of the copy you hold: a String, or the object you read. |
| `course_id:` | `String, nil` |  | The course. Defaults to the organization's default course. |

### `client.learners.remind`

**Remind a learner.** Emails the learner a reminder: the invite again if they haven't started, or a nudge to finish if they have.

```ruby
client.learners.remind(learner_id, course_id: nil,
                       request_options: {}) # => LearnerRemindAccepted
```

- **HTTP:** `POST /organizations/{orgId}/learners/{learnerId}:remind`.
- **Scopes:** `learners:write`.
- **Returns:** `LearnerRemindAccepted`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `learner_id` | `String` | Yes | The learner's canonical subject id (sub_… ULID). |
| `course_id:` | `String, nil` |  | The course. Defaults to the organization's default course. |

### `client.learners.retrieve`

**Retrieve a learner.** Retrieves a learner's status in one course.

```ruby
client.learners.retrieve(learner_id, course_id: nil,
                         request_options: {}) # => Learner
```

- **HTTP:** `GET /organizations/{orgId}/learners/{learnerId}`.
- **Scopes:** `learners:read`.
- **Returns:** `Learner`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `learner_id` | `String` | Yes | The learner's canonical subject id (sub_… ULID). |
| `course_id:` | `String, nil` |  | The course. Defaults to the organization's default course. |

### `client.learners.update`

**Update a learner.** Updates a learner's `name` or `externalId`; parameters you don't send are left unchanged. Send the body as `application/merge-patch+json` with the learner's current `ETag` in `If-Match`.

```ruby
client.learners.update(learner_id, if_match:, name: OMIT, external_id: OMIT,
                       course_id: nil, request_options: {}) # => Learner
```

- **HTTP:** `PATCH /organizations/{orgId}/learners/{learnerId}`.
- **Scopes:** `learners:write`.
- **Returns:** `Learner`.
- **Retries:** Never retried.
- **If-Match:** Required: `if_match:` takes the ETag or the object you read; a stale one raises `PreconditionFailedError`.
- **Body:** JSON merge patch: a keyword left out is unchanged; `nil` clears the field.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `learner_id` | `String` | Yes | The learner's canonical subject id (sub_… ULID). |
| `if_match:` | `String, Model` | Yes | The ETag of the copy you hold: a String, or the object you read. |
| `name:` | `String` |  | The learner's full name. |
| `external_id:` | `String, nil` |  | Your own id for the learner. Set it to `null` to clear it. |
| `course_id:` | `String, nil` |  | The course. Defaults to the organization's default course. |

### `client.learners.upsert_by_external_id`

**Create or retrieve a learner by your id.** Makes sure a learner exists for your own id. Creates and invites the learner the first time, and returns them on every later call, so a sync job can replay it safely. Never uses a second seat.

```ruby
client.learners.upsert_by_external_id(external_id, email:, name: nil,
                                      course_id: nil, delivery: nil,
                                      seat_policy: nil,
                                      request_options: {}) # => LearnerWriteResult
```

- **HTTP:** `PUT /organizations/{orgId}/learners/by-external-id/{externalId}`.
- **Scopes:** `learners:write`.
- **Returns:** `LearnerWriteResult`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `external_id` | `String` | Yes | Your id for the learner, URL-encoded. |
| `email:` | `String` | Yes | The learner's email address. |
| `name:` | `String, nil` |  | The learner's full name. |
| `course_id:` | `String, nil` |  | The course to invite them to. Defaults to the organization's default course. |
| `delivery:` | `String, Symbol, nil` |  | `email` (default) sends the invite email. `none` sends nothing and returns `joinUrl` for you to deliver. |
| `seat_policy:` | `String, Symbol, nil` |  | `require_available` fails with `409` when no seat is free. |

## Members

`client.members`

### `client.members.list`

**List all members.** Returns a list of the organization's members, its admins and learners. Pass `role=admin` to list only admins.

```ruby
client.members.list(limit: nil, cursor: nil, include: nil, role: nil,
                    request_options: {}) # => Page<MemberListItem>
```

- **HTTP:** `GET /organizations/{orgId}/members`.
- **Scopes:** `members:read`.
- **Returns:** `Page<MemberListItem>`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `limit:` | `Integer, nil` |  | How many objects to return, between 1 and 1000. Defaults to 20. |
| `cursor:` | `String, nil` |  | The `nextCursor` from the previous page. |
| `include:` | `String, nil` |  | Opt-in, comma-separated. With `enrollmentSubject`, a member whose `subjectId` is null carries `enrollmentSubjectId`: the subject their email resolves to (a never-signed-in invitee), or null when none. Use it only to match the member to Enrollments; it is not an address for member routes. With `holdsInvitation`, each learner carries `holdsInvitation`: whether the organization has an invitation for their email or a Seat bound to them. Each key is omitted when its lookup failed. |
| `role:` | `String, Symbol, nil` |  | Only admins (paginated). |

### `client.members.retrieve`

**Retrieve a member.** Retrieves a member of the organization.

```ruby
client.members.retrieve(subject_id, request_options: {}) # => Member
```

- **HTTP:** `GET /organizations/{orgId}/members/{subjectId}`.
- **Scopes:** `members:read`.
- **Returns:** `Member`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `subject_id` | `String` | Yes | The member's id. |

## Operations

`client.operations`

### `client.operations.retrieve`

**Retrieve an operation.** Retrieves a bulk operation and its result. Operations are kept for 24 hours.

```ruby
client.operations.retrieve(operation_id, request_options: {}) # => Operation
```

- **HTTP:** `GET /organizations/{orgId}/operations/{operationId}`.
- **Scopes:** Any Access token.
- **Returns:** `Operation`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `operation_id` | `String` | Yes | The server-minted opaque operation id. |

## Seats

`client.seats`

### `client.seats.retrieve`

**Retrieve the seat inventory.** Retrieves how many seats the organization has, how many are assigned and how many are available for new invites. Requires the `enrollments:read` scope.

```ruby
client.seats.retrieve(request_options: {}) # => SeatsInventory
```

- **HTTP:** `GET /organizations/{orgId}/seats`.
- **Scopes:** `enrollments:read`.
- **Returns:** `SeatsInventory`.
- **Retries:** Retried safely.

Takes no parameters besides `request_options:`.

## Webhook subscriptions

`client.webhook_subscriptions`

### `client.webhook_subscriptions.create`

**Create a webhook subscription.** Subscribes an HTTPS endpoint to event types and creates its signing secret. Requires the `webhooks:manage` or `org:admin` scope.

```ruby
client.webhook_subscriptions.create(endpoint_url:, event_types:,
                                    description: nil, seats_low_threshold: nil,
                                    request_options: {}) # => WebhookSubscriptionCreated
```

- **HTTP:** `POST /organizations/{orgId}/webhook-subscriptions`.
- **Scopes:** `org:admin` or `webhooks:manage`.
- **Returns:** `WebhookSubscriptionCreated`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `endpoint_url:` | `String` | Yes | The HTTPS URL to deliver events to. |
| `event_types:` | `Array<String, Symbol>` | Yes | The event types to deliver. |
| `description:` | `String, nil` |  | A description for your own reference. |
| `seats_low_threshold:` | `Integer, nil` |  | Send `seats.low` when available seats drop to this number. Defaults to 5. |

### `client.webhook_subscriptions.delete`

**Delete a webhook subscription.** Deletes a webhook subscription and its signing secret. Requires the `webhooks:manage` or `org:admin` scope.

```ruby
client.webhook_subscriptions.delete(subscription_id,
                                    request_options: {}) # => EmptyResponse
```

- **HTTP:** `DELETE /organizations/{orgId}/webhook-subscriptions/{subscriptionId}`.
- **Scopes:** `org:admin` or `webhooks:manage`.
- **Returns:** `EmptyResponse`.
- **Retries:** Never retried.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `subscription_id` | `String` | Yes | The webhook subscription id. |

### `client.webhook_subscriptions.list`

**List all webhook subscriptions.** Returns a list of the organization's webhook subscriptions. Signing secrets are never returned. Requires the `webhooks:manage` or `org:admin` scope.

```ruby
client.webhook_subscriptions.list(limit: nil, cursor: nil,
                                  request_options: {}) # => Page<WebhookSubscription>
```

- **HTTP:** `GET /organizations/{orgId}/webhook-subscriptions`.
- **Scopes:** `org:admin` or `webhooks:manage`.
- **Returns:** `Page<WebhookSubscription>`.
- **Retries:** Retried safely.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `limit:` | `Integer, nil` |  | How many objects to return, between 1 and 100. Defaults to 20. |
| `cursor:` | `String, nil` |  | The `nextCursor` from the previous page. |

### `client.webhook_subscriptions.redrive`

**Retry failed deliveries.** Delivers the subscription's failed events again. Requires the `webhooks:manage` or `org:admin` scope.

```ruby
client.webhook_subscriptions.redrive(subscription_id,
                                     request_options: {}) # => WebhookDeliveryOperation
```

- **HTTP:** `POST /organizations/{orgId}/webhook-subscriptions/{subscriptionId}:redrive`.
- **Scopes:** `org:admin` or `webhooks:manage`.
- **Returns:** `WebhookDeliveryOperation`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `subscription_id` | `String` | Yes | The webhook subscription id. |

### `client.webhook_subscriptions.retrieve`

**Retrieve a webhook subscription.** Retrieves a webhook subscription. Requires the `webhooks:manage` or `org:admin` scope.

```ruby
client.webhook_subscriptions.retrieve(subscription_id, if_none_match: nil,
                                      request_options: {}) # => WebhookSubscription
```

- **HTTP:** `GET /organizations/{orgId}/webhook-subscriptions/{subscriptionId}`.
- **Scopes:** `org:admin` or `webhooks:manage`.
- **Returns:** `WebhookSubscription, NotModified`.
- **Retries:** Retried safely.
- **If-None-Match:** `if_none_match:` returns `NotModified` when your copy is current.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `subscription_id` | `String` | Yes | The webhook subscription id. |
| `if_none_match:` | `String, Model` |  | The ETag of the copy you hold: a String, or the object you read. |

### `client.webhook_subscriptions.test`

**Send a test event.** Sends a signed test delivery to the subscription's endpoint, so you can check your verifier. Requires the `webhooks:manage` or `org:admin` scope.

```ruby
client.webhook_subscriptions.test(subscription_id,
                                  request_options: {}) # => WebhookDeliveryOperation
```

- **HTTP:** `POST /organizations/{orgId}/webhook-subscriptions/{subscriptionId}:test`.
- **Scopes:** `org:admin` or `webhooks:manage`.
- **Returns:** `WebhookDeliveryOperation`.
- **Retries:** Retried safely: sends a generated `Idempotency-Key`, reused by each retry.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `subscription_id` | `String` | Yes | The webhook subscription id. |

### `client.webhook_subscriptions.update`

**Update a webhook subscription.** Updates a webhook subscription; parameters you don't send are left unchanged. Send its current `ETag` in `If-Match`. The signing secret doesn't change. Requires the `webhooks:manage` or `org:admin` scope.

```ruby
client.webhook_subscriptions.update(subscription_id, if_match:,
                                    endpoint_url: OMIT, event_types: OMIT,
                                    enabled: OMIT, description: OMIT,
                                    seats_low_threshold: OMIT,
                                    request_options: {}) # => WebhookSubscription
```

- **HTTP:** `PATCH /organizations/{orgId}/webhook-subscriptions/{subscriptionId}`.
- **Scopes:** `org:admin` or `webhooks:manage`.
- **Returns:** `WebhookSubscription`.
- **Retries:** Never retried.
- **If-Match:** Required: `if_match:` takes the ETag or the object you read; a stale one raises `PreconditionFailedError`.
- **Body:** JSON merge patch: a keyword left out is unchanged; `nil` clears the field.

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `subscription_id` | `String` | Yes | The webhook subscription id. |
| `if_match:` | `String, Model` | Yes | The ETag of the copy you hold: a String, or the object you read. |
| `endpoint_url:` | `String` |  | The HTTPS URL to deliver events to. |
| `event_types:` | `Array<String, Symbol>` |  | The event types to deliver. |
| `enabled:` | `Boolean` |  | Turn deliveries on or off. |
| `description:` | `String, nil` |  | A description for your own reference. |
| `seats_low_threshold:` | `Integer` |  | Send `seats.low` when available seats drop to this number. |
