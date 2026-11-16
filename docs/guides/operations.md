# Operations and files

Some calls start work that outlives the HTTP request. Those return a
`TeachMeHipaa::Operation`, and you call `wait` on it when you want the
result. Files travel two ways: CSV exports and imports go through
Operations, and Certificate PDFs come back as bytes. The samples assume a
`client` built as in the [README](../../README.md#usage).

## Waiting on an Operation

Exports, imports, `learners.batch_upsert`, `enrollments.batch_by_filter`,
Test deliveries and redrives all return an Operation. It has a `name`, a
`done` flag, and once it's done, either a `response` or an `error`.

`wait` polls until the Operation is done and returns its final state. An
Operation that's already done, as every export is, returns at once without
another request:

<!-- sample: export-wait -->
```ruby
operation = client.certificates.export(format: "csv")
export = operation.wait(timeout: 120).export_result

File.write(export.filename || "certificates.csv", export.csv)
puts "#{export.row_count} Certificates"
```

`wait` takes two keywords:

- `timeout:` in seconds, 300 by default. When the Operation still isn't done,
  `wait` raises `OperationTimeoutError`, whose `operation` is the last state
  it saw.
- `interval:`, the first pause between polls, 1 second by default. Later
  pauses back off to 10 seconds.

An Operation that ends in an error raises `OperationFailedError`. It carries
the problem's `code` and `detail` like any API error, plus the `operation`:

<!-- sample: operation-errors -->
```ruby
begin
  client.webhook_subscriptions.redrive("whs_01JD8D").wait(timeout: 60)
rescue TeachMeHipaa::OperationFailedError => e
  puts "Redrive failed: #{e.code}"
rescue TeachMeHipaa::OperationTimeoutError => e
  puts "Still running; check #{e.operation.name} later"
end
```

To check back later, from another process or a later job, keep the id and
retrieve the Operation:

<!-- sample: operation-later -->
```ruby
operation = client.learners.export(format: "csv")
operation_id = TeachMeHipaa::Operation.operation_id_from_name(operation.name)

latest = client.operations.retrieve(operation_id)
puts latest.done
```

## CSV exports

`learners.export`, `enrollments.export` and `certificates.export` each return
a done Operation with the CSV inside. `export_result` decodes it into a
`TeachMeHipaa::ExportResult`: `csv` is the file as a String, `filename` a
suggested name, and `row_count` the data rows without the header.
`learners.export` also filters by `course_id:` and `status:`:

<!-- sample: export-learners -->
```ruby
export = client.learners.export(format: "csv", status: "expired").wait.export_result
puts "#{export.filename}: #{export.row_count} rows"
```

The file holds Learners' names and emails. Store it the way you'd store any
other personal data.

## Certificate PDFs

`certificates.download_pdf` returns a `TeachMeHipaa::BinaryResponse` with
the bytes in `data`, plus `content_type` and `filename`. Give it a block and
it streams the body to the block in chunks instead, then returns a
`TeachMeHipaa::StreamedResponse` with the `content_type` and `filename`.
Streaming keeps big files and web responses out of memory:

<!-- sample: pdf-download -->
```ruby
pdf = client.certificates.download_pdf("cert_01JD8F")
File.binwrite(pdf.filename || "certificate.pdf", pdf.data)

File.open("certificate-copy.pdf", "wb") do |file|
  client.certificates.download_pdf("cert_01JD8F") { |chunk| file.write(chunk) }
end
```

Only a successful PDF response reaches the block. After the first chunk, the
client won't retry the call: a dropped connection raises
`APIConnectionError` and your file never gets the opening bytes twice.

## CSV imports

`enrollments.import` invites everyone in a CSV with an `email` column (plus
optional `name` and `courseId` columns), up to 500 rows.
`enrollments.preview_import` checks the same file and invites nobody.

Both take the file as a path (a String or a `Pathname`), an IO opened in
binary mode, or a `TeachMeHipaa::FilePart`. A String always means a path, so
CSV text you built in memory goes in a `FilePart`:

<!-- sample: csv-import -->
```ruby
preview = client.enrollments.preview_import(file: "roster.csv", options: { course_id: "hipaa-2026" })
puts "#{preview.valid_rows} of #{preview.total_rows} rows are valid"
client.enrollments.import(file: Pathname("roster.csv"), options: { course_id: "hipaa-2026" }).wait

csv = "email,name\r\nana@example.com,Ana Example\r\n"
client.enrollments.import(file: TeachMeHipaa::FilePart.new(csv, filename: "march.csv"))
```

The client reads the file once per call, so a retry uploads the same bytes.
To sync one Learner at a time, `learners.upsert_by_external_id` is the
better fit; the [roster sync example](../../examples/sync_roster.rb) shows
it.
