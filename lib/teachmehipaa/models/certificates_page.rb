# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "certificate"

module TeachMeHipaa
  # A CertificatesPage object.
  class CertificatesPage < Model
    field :items, "items", type: [Certificate]
    field :next_cursor, "nextCursor"
  end
end
