# Models tolerate unknown fields and enums are open, whatever the spec says

The developer spec marks 27 of 39 response schemas `additionalProperties:
false` and publishes closed enums for `code`, Event types, audit types and
Seat order statuses. But `/v1` only ever grows by adding fields and values. So
generated models ignore unknown fields (and keep them reachable), and every
enum is generated as known constants plus "any other string". A
spec-faithful strict client would break for every partner on each additive
release.
