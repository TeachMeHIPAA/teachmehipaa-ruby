# frozen_string_literal: true

# Hand-written for the tracer; the generator replaces this file.
module TeachMeHipaa
  module Resources
    # Learners: Members taking a Training, seen from the Organization's side.
    class Learners < Core::Resource
      # Retrieves a Learner's status in one Course: the Organization's default
      # Course unless +course_id+ is given.
      def retrieve(learner_id, course_id: nil, request_options: {})
        request(
          method: "GET",
          path: "/organizations/{orgId}/learners/{learnerId}",
          path_params: { learnerId: learner_id },
          query: { courseId: course_id },
          model: Learner,
          request_options:,
        )
      end
    end
  end
end
