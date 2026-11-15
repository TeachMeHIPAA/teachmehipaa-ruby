# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An AuthorizationCodeTokenResponse object.
  class AuthorizationCodeTokenResponse < Model
    field :access_token, "access_token"
    # See AuthorizationCodeTokenResponseTokenType for known values; the API may send newer ones.
    field :token_type, "token_type"
    field :expires_in, "expires_in"
    field :refresh_token, "refresh_token"
    field :scope, "scope"
  end
end
