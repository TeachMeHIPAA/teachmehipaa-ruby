# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A TokenIntrospection object.
  class TokenIntrospection < Model
    # `client` for an API client, `user` for a person.
    #
    # See TokenIntrospectionActorType for known values; the API may send newer ones.
    field :actor_type, "actorType"
    # The API client the token belongs to.
    field :client_id, "clientId"
    # The person the token belongs to, for a user token.
    field :subject_id, "subjectId"
    # The organization the token is bound to, if any.
    field :org_id, "orgId"
    # The scopes the token holds.
    #
    # See TokenIntrospectionScopesItem for known values; the API may send newer ones.
    field :scopes, "scopes"
    # `test` for a Sandbox client, `live` otherwise.
    #
    # See TokenIntrospectionMode for known values; the API may send newer ones.
    field :mode, "mode"
    # When the token expires (ISO 8601).
    field :expires_at, "expiresAt", type: :time
  end
end
