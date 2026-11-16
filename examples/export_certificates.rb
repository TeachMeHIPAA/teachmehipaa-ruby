# frozen_string_literal: true

# Exports the Organization's Certificates as CSV, waits for the export, and
# saves it (to certificates.csv, or the path you pass).
#
#   TMH_CLIENT_ID=cli_... TMH_CLIENT_SECRET=tmh_cs_... bundle exec ruby -Ilib examples/export_certificates.rb [path]

require "teachmehipaa"

client = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  environment: :sandbox,
)

begin
  export = client.certificates.export(format: "csv").wait(timeout: 120).export_result
rescue TeachMeHipaa::OperationFailedError, TeachMeHipaa::OperationTimeoutError => e
  warn "The export didn't finish: #{e.message}"
  exit 1
end

path = ARGV.fetch(0, export.filename || "certificates.csv")
# The CSV holds Learners' names: keep the file somewhere only you can read.
File.write(path, export.csv, perm: 0o600)
puts "Saved #{export.row_count} rows to #{path}"
