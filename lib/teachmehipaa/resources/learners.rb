# frozen_string_literal: true

# Hand-written for the tracer; the generator replaces this file.
module TeachMeHipaa
  module Resources
    # Learners: Members taking a Training, seen from the Organization's side.
    class Learners < Core::Resource
      LEARNER_PATH = "/organizations/{orgId}/learners/{learnerId}"
      private_constant :LEARNER_PATH

      # Retrieves a Learner's status in one Course: the Organization's default
      # Course unless +course_id+ is given.
      def retrieve(learner_id, course_id: nil, request_options: {})
        request(
          method: "GET",
          path: LEARNER_PATH,
          path_params: { learnerId: learner_id },
          query: { courseId: course_id },
          model: Learner,
          retry_safe: true,
          request_options:,
        )
      end

      # Renames a Learner. +if_match+ is the ETag the Learner was read with.
      def update(learner_id, if_match:, name:, course_id: nil, request_options: {})
        request(
          method: "PATCH",
          path: LEARNER_PATH,
          path_params: { learnerId: learner_id },
          query: { courseId: course_id },
          headers: { "if-match" => if_match },
          body: { "name" => name },
          content_type: "application/merge-patch+json",
          model: Learner,
          request_options:,
        )
      end

      # Sends a Learner a reminder to finish their Training.
      def remind(learner_id, course_id: nil, request_options: {})
        request(
          method: "POST",
          path: "#{LEARNER_PATH}:remind",
          path_params: { learnerId: learner_id },
          query: { courseId: course_id },
          model: LearnerRemindAccepted,
          retry_safe: true,
          idempotency_key: :required,
          request_options:,
        )
      end

      # Creates a single-use Launch link that signs the Learner straight into
      # their Training.
      def create_launch_link(learner_id, course_id: nil, request_options: {})
        request(
          method: "POST",
          path: "#{LEARNER_PATH}:createLaunchLink",
          path_params: { learnerId: learner_id },
          query: { courseId: course_id },
          model: LearnerLaunchLink,
          retry_safe: true,
          request_options:,
        )
      end
    end
  end
end
