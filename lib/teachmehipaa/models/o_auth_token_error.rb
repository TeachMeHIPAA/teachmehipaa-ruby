# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An OAuthTokenError object.
  class OAuthTokenError < Model
    # See OAuthErrorCode for known values; the API may send newer ones.
    field :error, "error"
    field :error_description, "error_description"
  end
end
