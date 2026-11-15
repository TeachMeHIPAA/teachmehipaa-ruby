# Hand-written core, generated surface from one shared IR

Each SDK is a hand-written core (transport, auth, retries, errors, pagination,
webhooks, operations) plus a resource and model layer generated from
`openapi/sdk-ir.json`. That IR is built once, by `tooling/sdk-ir` in the
TeachMeHIPAA monorepo, from the developer OpenAPI document. Every SDK repo
vendors both the spec and the IR, so it builds on its own.

We chose this over stock openapi-generator, which mangles the spec's colon
custom-method paths, discriminator-less `oneOf`, null type arrays and
undeclared binaries. We also rejected per-repo generators that each interpret
raw OpenAPI: naming, renames and spec workarounds would then be decided six
times in six languages and drift apart. Generated files carry a "do not edit"
banner; fix the IR or the generator instead.
