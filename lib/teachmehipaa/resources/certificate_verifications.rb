# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.certificate_verifications+.
    class CertificateVerifications < Core::Resource
      # Verify a certificate
      #
      # Verifies the certificate behind a `https://tme.so/{tinyId}` link. Needs no access token.
      # Limited to 60 requests a minute per IP address.
      def retrieve(tiny_id, request_options: {})
        request(
          method: "GET",
          path: "/certificate-verifications/{tinyId}",
          path_params: { tinyId: tiny_id },
          retry_safe: true,
          model: CertificateVerification,
          request_options:,
        )
      end
    end
  end
end
