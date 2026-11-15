# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A Course object.
  class Course < Model
    # Unique identifier for the course.
    field :course_id, "courseId"
    # The course's title.
    field :title, "title"
    # The current version of the course content.
    field :course_version, "courseVersion"
    # The score needed to pass the course's assessment.
    field :passing_threshold, "passingThreshold"
  end
end
