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
      def batch_by_filter(operation:, select:, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments:batch",
          body: EnrollmentsBatchRequest.to_wire({ operation:, select: }),
          retry_safe: true,
          idempotency_key: :required,
          model: Operation,
          request_options:,
        )
      end

      # Cancel an enrollment
      #
      # Cancels an invite that hasn't been accepted yet and returns its seat to the pool. With
      # `refund: true`, refunds the seat to the card that paid for it instead. The enrollment
      # remains, with status `CANCELLED`. Requires the `enrollments:write` scope.
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
      def export(format:, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments:export",
          body: EnrollmentsExportRequest.to_wire({ format: }),
          retry_safe: true,
          idempotency_key: :required,
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
      def import(file:, options: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/enrollments:import",
          body: fixed(ImportEnrollmentsRequest.to_wire({ file:, options: }.compact), %w[options validateOnly], false),
          content_type: "multipart/form-data",
          binary_parts: { "file" => "text/csv" },
          retry_safe: true,
          idempotency_key: :required,
          model: Operation,
          request_options:,
        )
      end

      # List all enrollments
      #
      # Returns a list of the organization's enrollments. Filter by `status`, `courseId` or
      # `archived`. Requires the `enrollments:read` scope.
      def list(limit: nil, cursor: nil, status: nil, course_id: nil, archived: nil, include: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/enrollments",
          query: { limit:, cursor:, status:, courseId: course_id, archived:, include: },
          retry_safe: true,
          response: :page,
          model: OrgEnrollmentListItem,
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
      def retrieve(enrollment_id, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/enrollments/{enrollmentId}",
          path_params: { enrollmentId: enrollment_id },
          retry_safe: true,
          model: Enrollment,
          request_options:,
        )
      end
    end
  end
end
