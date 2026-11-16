# Examples

Small programs that use the library against the **Sandbox** Environment.
Each reads your Sandbox API client's credentials from `TMH_CLIENT_ID` and
`TMH_CLIENT_SECRET`. From a clone of this repository:

```sh
bundle install
export TMH_CLIENT_ID=cli_... TMH_CLIENT_SECRET=tmh_cs_...
bundle exec ruby -Ilib examples/quickstart.rb
```

| Program | What it shows |
| --- | --- |
| [`quickstart.rb`](quickstart.rb) | The course catalog, the Compliance summary and the first Learners |
| [`sync_roster.rb`](sync_roster.rb) | Syncing your roster with `learners.upsert_by_external_id`, and offboarding people who left |
| [`webhook_sinatra.rb`](webhook_sinatra.rb) | A Sinatra endpoint that verifies Deliveries and dispatches on the Event type (needs `TMH_WEBHOOK_SECRET`, the subscription's Signing secret) |
| [`export_certificates.rb`](export_certificates.rb) | Exporting Certificates as CSV and waiting for the Operation |

`sync_roster.rb` invites and offboards Learners, so run it only against a
Sandbox Organization. The test suite runs every example against a fake
transport (`test/examples_test.rb`), so they stay in step with the library.
