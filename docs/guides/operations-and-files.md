# Operations and files

Some work takes longer than one request, so the API answers with an
Operation that finishes later. This guide covers waiting for Operations, the
CSV exports they produce, Certificate PDF downloads, and CSV imports.

## Operations

Exports, imports, batch writes (`learners.batch_upsert`,
`enrollments.batch_by_filter`), Test deliveries and redrives return a
`TeachMeHipaa::Operation`. It has a `name`, `done`, and, once done, either a
`response` or an `error`.

`wait` polls until the Operation is done and returns it. An Operation that
is already done, as exports always are, returns at once without a request:

<!-- sample: export-wait -->
```ruby
operation = client.certificates.export(format: "csv")
export = operation.wait(timeout: 120).export_result

File.write(export.filename || "certificates.csv", export.csv)
puts "#{export.row_count} Certificates"
```

`wait` takes:

- `timeout:`, in seconds (300 by default). When the Operation is not done by
  then, `wait` raises `OperationTimeoutError`, whose `operation` is the last
  state it saw.
- `interval:`, the first wait between polls, in seconds (1 by default). Later
  polls back off to 10 seconds apart.

An Operation that finished with an error raises `OperationFailedError`,
which carries the problem's `code` and `detail` like any API error, and the
`operation`:

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

To check on an Operation later, from another process say, keep its id and
retrieve it:

<!-- sample: operation-later -->
```ruby
operation = client.learners.export(format: "csv")
operation_id = TeachMeHipaa::Operation.operation_id_from_name(operation.name)

latest = client.operations.retrieve(operation_id)
puts latest.done
```

## CSV exports

`learners.export`, `enrollments.export` and `certificates.export` return a
done Operation holding the CSV. `export_result` decodes it into a
`TeachMeHipaa::ExportResult` with `csv` (the file's text), `filename` and
`row_count` (data rows, not counting the header). `learners.export` takes a
`course_id:` and a `status:` to export only some Learners:

<!-- sample: export-learners -->
```ruby
export = client.learners.export(format: "csv", status: "expired").wait.export_result
puts "#{export.filename}: #{export.row_count} rows"
```

The CSV holds Learners' names and emails: treat the file accordingly.

## Certificate PDFs

`certificates.download_pdf` returns the PDF whole, as a
`TeachMeHipaa::BinaryResponse` with `data` (the bytes), `content_type` and
`filename`. Given a block, it streams the body to the block in chunks
instead and returns a `TeachMeHipaa::StreamedResponse` with the
`content_type` and `filename`, which suits large files and web responses:

<!-- sample: pdf-download -->
```ruby
pdf = client.certificates.download_pdf("cert_01JD8F")
File.binwrite(pdf.filename || "certificate.pdf", pdf.data)

File.open("certificate-copy.pdf", "wb") do |file|
  client.certificates.download_pdf("cert_01JD8F") { |chunk| file.write(chunk) }
end
```

Only a successful PDF response reaches the block. Once the block has
received bytes, the call is never retried, so a dropped connection raises
`APIConnectionError` rather than writing the start of the file twice.

## CSV imports

`enrollments.import` invites everyone in a CSV file with an `email` column
(and optional `name` and `courseId` columns), up to 500 rows.
`enrollments.preview_import` checks the same file without inviting anyone.
Both take the file as a path (a String or a `Pathname`), an IO opened in
binary mode, or a `TeachMeHipaa::FilePart`. A String is always a path, so
wrap CSV text you already hold in a `FilePart`:

<!-- sample: csv-import -->
```ruby
preview = client.enrollments.preview_import(file: "roster.csv", options: { course_id: "hipaa-2026" })
puts "#{preview.valid_rows} of #{preview.total_rows} rows are valid"
client.enrollments.import(file: Pathname("roster.csv"), options: { course_id: "hipaa-2026" }).wait

csv = "email,name\r\nana@example.com,Ana Example\r\n"
client.enrollments.import(file: TeachMeHipaa::FilePart.new(csv, filename: "march.csv"))
```

The file is read once per call, so a retry resends the same bytes. To keep
Learners in step with your own system one at a time, see
`learners.upsert_by_external_id` and the [roster sync
example](../../examples/sync_roster.rb).
