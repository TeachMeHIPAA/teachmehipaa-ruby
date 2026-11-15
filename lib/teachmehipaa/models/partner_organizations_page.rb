# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "partner_organization"

module TeachMeHipaa
  # A PartnerOrganizationsPage object.
  class PartnerOrganizationsPage < Model
    field :items, "items", type: [PartnerOrganization]
    field :next_cursor, "nextCursor"
  end
end
