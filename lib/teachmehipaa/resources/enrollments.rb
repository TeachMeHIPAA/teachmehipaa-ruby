# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.enrollments+.
    class Enrollments < Core::Resource
      # Update many enrollments
      #
      # Reminds, resends, cancels, renews, archives or unarchives up to 500 enrollments in one
      # request, chosen by id or by filter. Each enrollment succeeds or fails on its own. Requires
      # the `enrollments:write` scope.
      #
      # +select+ takes the form with +enrollment_ids+.
      #
      # Needs the +enrollments:write+ Scope.
      #
      # @param operation [String, Symbol] What to do to each enrollment: `remind`, `resendInvite`,
      #   `cancel`, `recertify`, `archive` or `unarchive`.
      # @param select [Hash] The enrollments to act on: a list of `enrollmentIds` (up to 500), or
      #   a `filter`.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [EnrollmentsBatchResults]
      def batch(operation:, select:, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments:batch",
          body: EnrollmentsBatchRequest.to_wire({ operation:, select: }),
          retry_safe: true,
          idempotency_key: :required,
          model: EnrollmentsBatchResults,
          request_options:,
        )
      end

      # Update many enrollments
      #
      # Reminds, resends, cancels, renews, archives or unarchives up to 500 enrollments in one
      # request, chosen by id or by filter. Each enrollment succeeds or fails on its own. Requires
      # the `enrollments:write` scope.
      #
      # +select+ takes the form with +filter+.
      #
      # Needs the +enrollments:write+ Scope.
      #
      # @param operation [String, Symbol] What to do to each enrollment: `remind`, `resendInvite`,
      #   `cancel`, `recertify`, `archive` or `unarchive`.
      # @param select [Hash] The enrollments to act on: a list of `enrollmentIds` (up to 500), or
      #   a `filter`.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Operation]
      def batch_by_filter(operation:, select:, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments:batch",
          body: EnrollmentsBatchRequest.to_wire({ operation:, select: }),
          retry_safe: true,
          idempotency_key: :required,
          response: :operation,
          model: Operation,
          request_options:,
        )
      end

      # Cancel an enrollment
      #
      # Cancels an invite that hasn't been accepted yet and returns its seat to the pool. With
      # `refund: true`, refunds the seat to the card that paid for it instead. The enrollment
      # remains, with status `CANCELLED`. Requires the `enrollments:write` scope.
      #
      # Needs the +enrollments:write+ Scope.
      #
      # @param enrollment_id [String]
      # @param refund [Boolean, nil] Refund the seat to the card that paid for it instead of
      #   returning it to the pool. Defaults to `false`.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [CancelEnrollmentResponse]
      def cancel(enrollment_id, refund: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments/{enrollmentId}:cancel",
          path_params: { enrollmentId: enrollment_id },
          body: EnrollmentCancelRequest.to_wire({ refund: }.compact),
          retry_safe: true,
          idempotency_key: :required,
          model: CancelEnrollmentResponse,
          request_options:,
        )
      end

      # Create an enrollment
      #
      # Invites a person to a course, creating their profile if needed, and uses one seat. The
      # course defaults to `hipaa`. Requires the `enrollments:write` scope.
      #
      # Needs the +enrollments:write+ Scope.
      #
      # @param email [String] The learner's email address.
      # @param name [String, nil] The learner's full name.
      # @param course_id [String, nil] The course to invite them to. Defaults to `hipaa`.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Enrollment]
      def create(email:, name: nil, course_id: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments",
          body: EnrollmentCreateRequest.to_wire({ email:, name:, course_id: }.compact),
          retry_safe: true,
          idempotency_key: :required,
          model: Enrollment,
          request_options:,
        )
      end

      # Export enrollments
      #
      # Exports the organization's enrollments as CSV. Requires the `enrollments:read` scope.
      #
      # Needs the +enrollments:read+ Scope.
      #
      # @param format [String, Symbol] The file format. Only `csv` today.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Operation]
      def export(format:, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments:export",
          body: EnrollmentsExportRequest.to_wire({ format: }),
          retry_safe: true,
          idempotency_key: :required,
          response: :operation,
          model: Operation,
          request_options:,
        )
      end

      # Import learners from CSV
      #
      # Invites everyone in a CSV file with an `email` column (and optional `name` and `courseId`).
      # Send `validateOnly: true` first to preview the file without inviting anyone. Up to 500 rows.
      # Requires the `enrollments:write` scope.
      #
      # Sets +options.validate_only+ to false itself.
      #
      # Needs the +enrollments:write+ Scope.
      #
      # @param file [String, Pathname, IO, FilePart] UTF-8 CSV (RFC 4180: quoted fields, `""`
      #   escapes, CRLF/LF). Header row required.
      # @param options [Hash, nil]
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Operation]
      def import(file:, options: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments:import",
          body: fixed(ImportEnrollmentsRequest.to_wire({ file:, options: }.compact), %w[options validateOnly], false),
          content_type: "multipart/form-data",
          binary_parts: { "file" => "text/csv" },
          retry_safe: true,
          idempotency_key: :required,
          response: :operation,
          model: Operation,
          request_options:,
        )
      end

      # List all enrollments
      #
      # Returns a list of the organization's enrollments. Filter by `status`, `courseId` or
      # `archived`. Requires the `enrollments:read` scope.
      #
      # Needs the +enrollments:read+ Scope.
      #
      # @param limit [Integer, nil] How many objects to return, between 1 and 1000. Defaults to
      #   20.
      # @param cursor [String, nil] The `nextCursor` from the previous page.
      # @param status [String, Symbol, nil] Filter on the derived effectiveStatus.
      # @param course_id [String, nil]
      # @param archived [String, Symbol, nil]
      # @param include [String, Symbol, nil] Opt-in enrichment. With `priorCertificate`, an item
      #   carries `priorCertificate` (object, or null when the server confirmed there is none). The
      #   key is omitted on an item whose answer is unknown, and on every item of the page if the
      #   certificate lookup failed; clients must treat a missing key as unknown, never as null.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Page<OrgEnrollmentListItem>]
      def list(limit: nil, cursor: nil, status: nil, course_id: nil, archived: nil, include: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/enrollments",
          query: { limit:, cursor:, status:, courseId: course_id, archived:, include: },
          retry_safe: true,
          response: :page,
          model: OrgEnrollmentListItem,
          pagination: { style: :cursor, cursor_param: "cursor" },
          request_options:,
        )
      end

      # Import learners from CSV
      #
      # Invites everyone in a CSV file with an `email` column (and optional `name` and `courseId`).
      # Send `validateOnly: true` first to preview the file without inviting anyone. Up to 500 rows.
      # Requires the `enrollments:write` scope.
      #
      # Sets +options.validate_only+ to true itself.
      #
      # Needs the +enrollments:write+ Scope.
      #
      # @param file [String, Pathname, IO, FilePart] UTF-8 CSV (RFC 4180: quoted fields, `""`
      #   escapes, CRLF/LF). Header row required.
      # @param options [Hash, nil]
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [ImportPreview]
      def preview_import(file:, options: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments:import",
          body: fixed(ImportEnrollmentsRequest.to_wire({ file:, options: }.compact), %w[options validateOnly], true),
          content_type: "multipart/form-data",
          binary_parts: { "file" => "text/csv" },
          retry_safe: true,
          idempotency_key: :required,
          model: ImportPreview,
          request_options:,
        )
      end

      # Remind an enrollment
      #
      # Emails the learner again: the invitation if they haven't joined, or a reminder linking to
      # the training if they have. Requires the `enrollments:write` scope.
      #
      # Needs the +enrollments:write+ Scope.
      #
      # @param enrollment_id [String]
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [EnrollmentActionAccepted]
      def remind(enrollment_id, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments/{enrollmentId}:remind",
          path_params: { enrollmentId: enrollment_id },
          retry_safe: true,
          idempotency_key: :required,
          model: EnrollmentActionAccepted,
          request_options:,
        )
      end

      # Renew an enrollment
      #
      # Starts the next certification cycle for a certified learner and invites them again, using
      # one seat. Retrying never uses a second seat. Requires the `enrollments:write` scope.
      #
      # Needs the +enrollments:write+ Scope.
      #
      # @param enrollment_id [String]
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Enrollment]
      def renew(enrollment_id, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments/{enrollmentId}:renew",
          path_params: { enrollmentId: enrollment_id },
          retry_safe: true,
          idempotency_key: :required,
          model: Enrollment,
          request_options:,
        )
      end

      # Resend an invite
      #
      # Sends a pending invite again, within the same cycle. To invite a certified learner again,
      # renew the enrollment. Requires the `enrollments:write` scope.
      #
      # Needs the +enrollments:write+ Scope.
      #
      # @param enrollment_id [String]
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [EnrollmentActionAccepted]
      def resend_invite(enrollment_id, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments/{enrollmentId}:resendInvite",
          path_params: { enrollmentId: enrollment_id },
          retry_safe: true,
          idempotency_key: :required,
          model: EnrollmentActionAccepted,
          request_options:,
        )
      end

      # Retrieve an enrollment
      #
      # Retrieves an enrollment. Requires the `enrollments:read` scope.
      #
      # Given +if_none_match:+ (an ETag, or the copy you hold), returns NotModified when your copy
      # is current.
      #
      # Needs the +enrollments:read+ Scope.
      #
      # @param enrollment_id [String]
      # @param if_none_match [String, Model] The ETag of the copy you hold: a String, or the
      #   object you read.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Enrollment, NotModified]
      def retrieve(enrollment_id, if_none_match: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/enrollments/{enrollmentId}",
          path_params: { enrollmentId: enrollment_id },
          if_none_match:,
          retry_safe: true,
          model: Enrollment,
          request_options:,
        )
      end
    end
  end
end
