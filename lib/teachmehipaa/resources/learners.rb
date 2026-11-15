# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.learners+.
    class Learners < Core::Resource
      # Create many learners
      #
      # Creates or retrieves up to 500 learners in one request. Each item works like creating one
      # learner and succeeds or fails on its own.
      def batch_upsert(items:, delivery: nil, seat_policy: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/learners:batchUpsert",
          body: LearnerBatchUpsertRequest.to_wire({ items:, delivery:, seat_policy: }.compact),
          retry_safe: true,
          idempotency_key: :required,
          response: :operation,
          model: Operation,
          request_options:,
        )
      end

      # Create a learner
      #
      # Adds a person to the organization and invites them to a course in one call, using one seat.
      # If the email or `externalId` already belongs to an active learner in the course, nothing is
      # created. With `delivery: "none"`, no email is sent and the response includes a `joinUrl` for
      # you to deliver.
      def create(email:, name: nil, external_id: nil, course_id: nil, delivery: nil, seat_policy: nil,
                 request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/learners",
          body: LearnerCreateRequest.to_wire({ email:, name:, external_id:, course_id:, delivery:,
                                               seat_policy: }.compact),
          retry_safe: true,
          idempotency_key: :required,
          response: :write_result,
          model: LearnerWriteResult,
          request_options:,
        )
      end

      # Create a launch link
      #
      # Creates a link that opens the course with the learner already signed in, for a "Start
      # training" button in your product. The link works once and expires after 5 minutes: create it
      # when the learner clicks, then redirect them to it. Never email, store or log it. Only for a
      # learner who has accepted their invite.
      def create_launch_link(learner_id, course_id: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/learners/{learnerId}:createLaunchLink",
          path_params: { learnerId: learner_id },
          query: { courseId: course_id },
          retry_safe: true,
          model: LearnerLaunchLink,
          request_options:,
        )
      end

      # Export learners
      #
      # Exports the organization's learners in one course as CSV, optionally only those with one
      # `status`. Requires the `learners:read` scope.
      def export(format:, course_id: nil, status: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/learners:export",
          body: LearnersExportRequest.to_wire({ format:, course_id:, status: }.compact),
          retry_safe: true,
          idempotency_key: :required,
          response: :operation,
          model: Operation,
          request_options:,
        )
      end

      # List all learners
      #
      # Returns a list of the organization's learners in one course, with each learner's status,
      # dates and current certificate. Filter by `status`, or find one learner by `email` or
      # `externalId`.
      def list(limit: nil, cursor: nil, email: nil, external_id: nil, status: nil, course_id: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/learners",
          query: { limit:, cursor:, email:, externalId: external_id, status:, courseId: course_id },
          retry_safe: true,
          response: :page,
          model: Learner,
          pagination: { style: :cursor, cursor_param: "cursor" },
          request_options:,
        )
      end

      # Offboard a learner
      #
      # Removes a learner from the organization. A learner who hasn't started has their invite
      # cancelled and the seat returned; a learner who has started keeps their training history and
      # certificates. Releases the learner's `externalId`.
      def offboard(learner_id, if_match: nil, course_id: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/learners/{learnerId}:offboard",
          path_params: { learnerId: learner_id },
          query: { courseId: course_id },
          if_match:,
          retry_safe: true,
          idempotency_key: :required,
          model: Learner,
          request_options:,
        )
      end

      # Remind a learner
      #
      # Emails the learner a reminder: the invite again if they haven't started, or a nudge to
      # finish if they have.
      def remind(learner_id, course_id: nil, request_options: {})
        request(
          method: "POST",
          path: "/organizations/{orgId}/learners/{learnerId}:remind",
          path_params: { learnerId: learner_id },
          query: { courseId: course_id },
          retry_safe: true,
          idempotency_key: :required,
          model: LearnerRemindAccepted,
          request_options:,
        )
      end

      # Retrieve a learner
      #
      # Retrieves a learner's status in one course.
      def retrieve(learner_id, course_id: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/learners/{learnerId}",
          path_params: { learnerId: learner_id },
          query: { courseId: course_id },
          retry_safe: true,
          model: Learner,
          request_options:,
        )
      end

      # Update a learner
      #
      # Updates a learner's `name` or `externalId`; parameters you don't send are left unchanged.
      # Send the body as `application/merge-patch+json` with the learner's current `ETag` in
      # `If-Match`.
      #
      # Parameters you leave out are unchanged; pass nil to clear one.
      def update(learner_id, if_match:, name: OMIT, external_id: OMIT, course_id: nil, request_options: {})
        request(
          method: "PATCH",
          path: "/organizations/{orgId}/learners/{learnerId}",
          path_params: { learnerId: learner_id },
          query: { courseId: course_id },
          if_match:,
          body: LearnerPatch.to_wire({ name:, external_id: }),
          content_type: "application/merge-patch+json",
          model: Learner,
          request_options:,
        )
      end

      # Create or retrieve a learner by your id
      #
      # Makes sure a learner exists for your own id. Creates and invites the learner the first time,
      # and returns them on every later call, so a sync job can replay it safely. Never uses a
      # second seat.
      def upsert_by_external_id(external_id, email:, name: nil, course_id: nil, delivery: nil, seat_policy: nil,
                                request_options: {})
        request(
          method: "PUT",
          path: "/organizations/{orgId}/learners/by-external-id/{externalId}",
          path_params: { externalId: external_id },
          body: LearnerUpsertRequest.to_wire({ email:, name:, course_id:, delivery:, seat_policy: }.compact),
          retry_safe: true,
          idempotency_key: :required,
          response: :write_result,
          model: LearnerWriteResult,
          request_options:,
        )
      end
    end
  end
end
