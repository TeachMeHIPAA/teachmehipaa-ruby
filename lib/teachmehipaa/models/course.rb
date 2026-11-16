# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A Course object.
  class Course < Model
    # Unique identifier for the course.
    #
    # @return [String]
    field :course_id, "courseId"
    # The course's title.
    #
    # @return [String]
    field :title, "title"
    # The current version of the course content.
    #
    # @return [String]
    field :course_version, "courseVersion"
    # The score needed to pass the course's assessment.
    #
    # @return [Numeric]
    field :passing_threshold, "passingThreshold"
  end
end
