# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # The course the learner was invited to.
  class LearnerCreatedCourse < Model
    # @return [String]
    field :course_id, "courseId"
    # @return [String]
    field :title, "title"
  end
end
