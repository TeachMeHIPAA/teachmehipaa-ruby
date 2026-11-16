# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A CertificateLinks object.
  class CertificateLinks < Model
    # The certificate.
    #
    # @return [String]
    field :certificate_id, "certificateId"
    # Adds the certificate to the holder's LinkedIn profile.
    #
    # @return [String]
    field :linked_in_url, "linkedInUrl"
    # The public `tme.so` verification link.
    #
    # @return [String]
    field :short_link, "shortLink"
    # The verification link's id.
    #
    # @return [String]
    field :tiny_id, "tinyId"
    # @return [Boolean, nil]
    field :paywalled, "paywalled"
  end
end
