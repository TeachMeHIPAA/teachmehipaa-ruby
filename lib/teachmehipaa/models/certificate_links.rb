# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A CertificateLinks object.
  class CertificateLinks < Model
    # The certificate.
    field :certificate_id, "certificateId"
    # Adds the certificate to the holder's LinkedIn profile.
    field :linked_in_url, "linkedInUrl"
    # The public `tme.so` verification link.
    field :short_link, "shortLink"
    # The verification link's id.
    field :tiny_id, "tinyId"
    field :paywalled, "paywalled"
  end
end
