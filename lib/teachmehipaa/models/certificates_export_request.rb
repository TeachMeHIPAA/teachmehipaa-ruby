# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A CertificatesExportRequest object.
  class CertificatesExportRequest < Model
    # The file format. Only `csv` today.
    #
    # See CertificatesExportRequestFormat for known values; the API may send newer ones.
    field :format, "format"
  end
end
