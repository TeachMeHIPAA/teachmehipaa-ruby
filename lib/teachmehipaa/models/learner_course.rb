# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # The course this learner record is for.
  class LearnerCourse < Model
    # @return [String]
    field :course_id, "courseId"
    # @return [String]
    field :title, "title"
  end
end
