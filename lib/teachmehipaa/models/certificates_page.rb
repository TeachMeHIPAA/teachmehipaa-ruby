# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "certificate"

module TeachMeHipaa
  # A CertificatesPage object.
  class CertificatesPage < Model
    # @return [Array<Certificate>]
    field :items, "items", type: [Certificate]
    # @return [String, nil]
    field :next_cursor, "nextCursor"
  end
end
