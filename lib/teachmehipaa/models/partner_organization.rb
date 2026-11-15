# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A PartnerOrganization object.
  class PartnerOrganization < Model
    field :org_id, "orgId"
    field :name, "name"
    field :created_at, "createdAt", type: :time
    field :grant_active, "grantActive"
  end
end
