# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "partner_organization_created_grant"

module TeachMeHipaa
  # A PartnerOrganizationCreated object.
  class PartnerOrganizationCreated < Model
    # The new organization's id.
    field :org_id, "orgId"
    # The organization's name.
    field :name, "name"
    # When it was created (ISO 8601).
    field :created_at, "createdAt", type: :time
    # Your app's connection to the organization.
    field :grant, "grant", type: PartnerOrganizationCreatedGrant
    # Returned only once. Exchange it at `POST /v1/auth/token` for the organization's tokens.
    field :refresh_token, "refresh_token"
  end
end
