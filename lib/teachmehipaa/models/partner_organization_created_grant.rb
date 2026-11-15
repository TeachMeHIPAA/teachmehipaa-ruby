# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Your app's connection to the organization.
  class PartnerOrganizationCreatedGrant < Model
    field :grant_id, "grantId"
    # See PartnerOrganizationCreatedGrantScopesItem for known values; the API may send newer ones.
    field :scopes, "scopes"
  end
end
