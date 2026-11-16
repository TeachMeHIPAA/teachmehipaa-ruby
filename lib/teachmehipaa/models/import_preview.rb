# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "import_preview_rows_item"

module TeachMeHipaa
  # An ImportPreview object.
  class ImportPreview < Model
    # Rows in the file.
    #
    # @return [Integer]
    field :total_rows, "totalRows"
    # Rows that would be invited.
    #
    # @return [Integer]
    field :valid_rows, "validRows"
    # Seats the import would use.
    #
    # @return [Integer]
    field :seats_required, "seatsRequired"
    # Seats available now.
    #
    # @return [Integer]
    field :seats_available, "seatsAvailable"
    # Each row's result: `valid`, `invalid_email`, `duplicate_in_file`, `already_enrolled` or
    # `already_invited`.
    #
    # @return [Array<ImportPreviewRowsItem>]
    field :rows, "rows", type: [ImportPreviewRowsItem]
  end
end
