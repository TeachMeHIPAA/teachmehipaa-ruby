# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.certificates+.
    class Certificates < Core::Resource
      # Download a certificate
      #
      # Downloads the certificate as a PDF. Revoked and expired certificates are watermarked.
      # Requires the `certificates:read` scope.
      #
      # Returns the whole file as a BinaryResponse. Given a block, yields the file's bytes in chunks
      # as they arrive instead and returns a StreamedResponse.
      def download_pdf(cert_id, request_options: {}, &)
        request(
          method: "GET",
          path: "/organizations/{orgId}/certificates/{certId}/content",
          path_params: { certId: cert_id },
          retry_safe: true,
          response: :binary,
          accept: "application/pdf",
          request_options:,
          &
        )
      end

      # Export certificates
      #
      # Exports the organization's certificate records as CSV. Requires the `certificates:read`
      # scope.
      def export(format:, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/certificates:export",
          body: CertificatesExportRequest.to_wire({ format: }),
          retry_safe: true,
          idempotency_key: :required,
          response: :operation,
          model: Operation,
          request_options:,
        )
      end

      # List all certificates
      #
      # Returns a list of the organization's certificates. Pass `subjectId` to list one learner's.
      def list(limit: nil, cursor: nil, subject_id: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/certificates",
          query: { limit:, cursor:, subjectId: subject_id },
          retry_safe: true,
          response: :page,
          model: Certificate,
          pagination: { style: :cursor, cursor_param: "cursor" },
          request_options:,
        )
      end

      # Retrieve a certificate
      #
      # Retrieves a certificate.
      def retrieve(cert_id, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/certificates/{certId}",
          path_params: { certId: cert_id },
          retry_safe: true,
          model: Certificate,
          request_options:,
        )
      end

      # Retrieve certificate links
      #
      # Retrieves the certificate's LinkedIn add-to-profile link and its public `tme.so`
      # verification link. Requires the `certificates:read` scope.
      def retrieve_links(cert_id, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/certificates/{certId}/credentials",
          path_params: { certId: cert_id },
          retry_safe: true,
          model: CertificateLinks,
          request_options:,
        )
      end
    end
  end
end
