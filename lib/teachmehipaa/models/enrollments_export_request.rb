# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An EnrollmentsExportRequest object.
  class EnrollmentsExportRequest < Model
    # The file format. Only `csv` today.
    #
    # See EnrollmentsExportRequestFormat for known values; the API may send newer ones.
    #
    # @return [String]
    field :format, "format"
  end
end
