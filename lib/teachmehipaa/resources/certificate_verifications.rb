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
      #
      # Sends no Access token, so it also works on a client built without credentials.
      #
      # @param tiny_id [String] The id at the end of the certificate's tme.so link.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [CertificateVerification]
      def retrieve(tiny_id, request_options: {})
        request(
          method: "GET",
          path: "/certificate-verifications/{tinyId}",
          path_params: { tinyId: tiny_id },
          retry_safe: true,
          authenticated: false,
          model: CertificateVerification,
          request_options:,
        )
      end
    end
  end
end
