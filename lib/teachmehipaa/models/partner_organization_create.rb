# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A PartnerOrganizationCreate object.
  class PartnerOrganizationCreate < Model
    # The organization's name.
    field :name, "name"
    # The email address of the organization's administrator.
    field :admin_email, "adminEmail"
    # The administrator's full name.
    field :admin_name, "adminName"
    # The scopes your app gets on the new organization. A subset of your app's scopes.
    #
    # See PartnerOrganizationCreateScopesItem for known values; the API may send newer ones.
    field :scopes, "scopes"
  end
end
