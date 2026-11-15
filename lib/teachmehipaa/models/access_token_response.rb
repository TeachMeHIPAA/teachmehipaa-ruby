# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An AccessTokenResponse object.
  class AccessTokenResponse < Model
    # See AccessTokenResponseTokenType for known values; the API may send newer ones.
    field :token_type, "tokenType"
    field :access_token, "accessToken"
    field :expires_in_sec, "expiresInSec"
    # See AccessTokenResponseScopesItem for known values; the API may send newer ones.
    field :scopes, "scopes"
  end
end
