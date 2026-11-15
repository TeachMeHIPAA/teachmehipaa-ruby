# The Organization is bound to the client, not passed per call

Every org-scoped path contains `{orgId}`, but an API client's or Grant's
Access token is bound to one Organization, and any other `orgId` is rejected
(403 `org_not_active`). So the SDK holds the Organization on the client:
callers may pass `organizationId`, and otherwise it's resolved once via
`GET /auth/introspection`. Org-scoped methods never take `orgId` as a
parameter. Serving several Organizations means one client per Grant.
`partners.*` methods take `partnerId` explicitly, because no endpoint reveals
it.
