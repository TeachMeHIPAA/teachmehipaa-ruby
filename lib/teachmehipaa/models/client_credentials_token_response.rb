# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A ClientCredentialsTokenResponse object.
  class ClientCredentialsTokenResponse < Model
    # The access token. Send it as `Authorization: Bearer`.
    field :access_token, "access_token"
    # Always `Bearer`.
    #
    # See ClientCredentialsTokenResponseTokenType for known values; the API may send newer ones.
    field :token_type, "token_type"
    # Seconds until the token expires.
    field :expires_in, "expires_in"
    # The scopes the token holds, space-delimited.
    field :scope, "scope"
  end
end
