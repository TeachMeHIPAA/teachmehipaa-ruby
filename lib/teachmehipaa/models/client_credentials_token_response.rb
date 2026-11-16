# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A ClientCredentialsTokenResponse object.
  class ClientCredentialsTokenResponse < Model
    # The access token. Send it as `Authorization: Bearer`.
    #
    # @return [String]
    field :access_token, "access_token"
    # Always `Bearer`.
    #
    # See ClientCredentialsTokenResponseTokenType for known values; the API may send newer ones.
    #
    # @return [String]
    field :token_type, "token_type"
    # Seconds until the token expires.
    #
    # @return [Integer]
    field :expires_in, "expires_in"
    # The scopes the token holds, space-delimited.
    #
    # @return [String]
    field :scope, "scope"
  end
end
