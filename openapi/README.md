# Vendored contract

Do not edit these files by hand.

- `openapi.developer.json`: the TeachMeHIPAA Developer API OpenAPI 3.1 document (`/openapi.developer.json`).
- `sdk-ir.json` and `sdk-ir.schema.json`: the normalized SDK IR built from it by `tooling/sdk-ir` in the TeachMeHIPAA monorepo (ADR-0001). The generator in this repo reads only `sdk-ir.json`.
- `../OPENAPI_VERSION`: the spec release these were built from.

To update: rebuild the IR in the monorepo (`bun tooling/sdk-ir/bin.ts --spec <spec> --out <dir>`), copy all three files here, update `OPENAPI_VERSION`, then regenerate.
