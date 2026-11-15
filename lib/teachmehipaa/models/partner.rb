# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A Partner object.
  class Partner < Model
    # Unique identifier for the partner account.
    field :partner_id, "partnerId"
    # The partner's name.
    field :name, "name"
    # The partner app.
    field :app_id, "appId"
    # `active` or `suspended`.
    #
    # See PartnerStatus for known values; the API may send newer ones.
    field :status, "status"
    # How many organizations the partner can create.
    field :max_child_orgs, "maxChildOrgs"
    # How many it has created.
    field :child_org_count, "childOrgCount"
    # When it was created (ISO 8601).
    field :created_at, "createdAt", type: :time
  end
end
