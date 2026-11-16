# Models tolerate unknown fields and enums are open, whatever the spec says

The developer spec marks 19 of 29 response schemas `additionalProperties:
false` and publishes closed enums for `code`, Event types and audit types.
But `/v1` only ever grows by adding fields and values. So generated models
ignore unknown fields (and keep them reachable), and every enum is generated
as known constants plus "any other string". A spec-faithful strict client
would break for every partner on each additive release.
