# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "import_options"

module TeachMeHipaa
  # An ImportEnrollmentsRequest object.
  class ImportEnrollmentsRequest < Model
    # UTF-8 CSV (RFC 4180: quoted fields, `""` escapes, CRLF/LF). Header row required.
    field :file, "file"
    field :options, "options", type: ImportOptions
  end
end
