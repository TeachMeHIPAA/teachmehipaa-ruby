# Zero dependencies and generated model readers instead of a dynamic object

`teachmehipaa-ruby` uses only the standard library (`net/http`, `openssl`,
`json`). Models are generated classes on a small `TeachMeHipaa::Model` base,
with typed readers, `to_h` and `[]` for unknown keys, plus RBS signatures in
`sig/`. Stripe's `StripeObject` instead uses `method_missing`, which hides the
schema from editors and type checkers. All configuration is per client and
frozen; Stripe still reads timeouts and retries from global config.
