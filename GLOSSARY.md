# TeachMeHIPAA SDKs

The official client libraries and CLI for the TeachMeHIPAA Developer API, used
by partners to enroll their people in HIPAA training and track compliance from
their own systems. Terms follow the platform glossary.

## Access

**API client**:
A machine credential (client id and secret) bound to exactly one Organization,
created by an Organization admin.
_Avoid_: API key, app, client (alone)

**Partner app**:
A machine credential that many Organizations connect to through consent; each
connection is a separate Grant.
_Avoid_: integration, OAuth app

**Partner**:
A reseller that creates and manages customer Organizations of its own.
_Avoid_: reseller account, parent org

**Grant**:
One Organization's consent for one Partner app, carried by a Refresh token.
_Avoid_: connection, authorization

**Access token**:
A short-lived bearer credential that authorizes requests for one Organization
(or one Partner).
_Avoid_: session, JWT

**Refresh token**:
The long-lived secret of a Grant that is exchanged for Access tokens and is
replaced on every exchange.
_Avoid_: offline token

**Scope**:
A named permission an Access token carries, such as `learners:write`.
_Avoid_: permission, role

**Environment**:
Which TeachMeHIPAA deployment a credential belongs to: **Live** or
**Sandbox**. Credentials never work across Environments.
_Avoid_: mode, test mode, staging

## Training

**Organization**:
The tenant: a company whose people take training.
_Avoid_: account, tenant, customer

**Member**:
Anyone who belongs to an Organization, admins included.
_Avoid_: user, employee

**Learner**:
A Member taking a Training, seen from the Organization's side.
_Avoid_: student, trainee, employee

**External ID**:
The partner's own identifier for a Learner, unique within an Organization.
_Avoid_: foreign key, partner id

**Course**:
A training offering a Learner can be enrolled in.
_Avoid_: program, class

**Enrollment**:
The lasting relationship between one Learner and one Course.
_Avoid_: registration, assignment

**Seat**:
A paid license allocation an Organization holds for one Learner at a time.
_Avoid_: token, license key

**Seat order**:
A purchase of Seats charged to the Organization's saved payment method.
_Avoid_: checkout, invoice

**Certificate**:
The document proving a Learner completed a Course, with issue and expiry
dates.
_Avoid_: credential, diploma

**Certificate verification**:
The public record anyone can look up to confirm a Certificate is genuine.
_Avoid_: validation

**Compliance summary**:
An Organization's current count of Learners by training status.
_Avoid_: report, dashboard

**Launch link**:
A one-time URL that signs a Learner straight into their Training.
_Avoid_: magic link, join link, SSO link

**Audit event**:
A record of a change someone made inside an Organization.
_Avoid_: log entry, activity

## Integration

**Event**:
A notification that something happened in an Organization, kept in the
Organization's event log for 30 days.
_Avoid_: webhook (for the notification itself), message

**Event type**:
The kind of an Event, such as `learner.certified`. New Event types are added
over time; existing ones are never removed.
_Avoid_: topic, event name

**Webhook subscription**:
A partner endpoint registered to receive Events of chosen Event types.
_Avoid_: webhook, endpoint, hook

**Delivery**:
One signed POST of an Event to a Webhook subscription's endpoint, retried
until it succeeds or is dead-lettered.
_Avoid_: webhook call, notification

**Test delivery**:
A signed POST sent on request to check an endpoint; it carries no Event.
_Avoid_: test event, ping event

**Signing secret**:
The per-subscription secret that proves a Delivery came from TeachMeHIPAA.
_Avoid_: webhook key, shared secret

**Operation**:
A piece of work that may finish after the request that started it returns,
such as an export or a redrive.
_Avoid_: job, task, LRO

**Custom method**:
An action on a resource that isn't create, read, update or delete, such as
cancelling an Enrollment.
_Avoid_: RPC, verb endpoint
