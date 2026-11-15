# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An ImportOptions object.
  class ImportOptions < Model
    # The course to invite everyone to. Defaults to the organization's default course.
    field :course_id, "courseId"
    # Check the file and return a preview without inviting anyone.
    field :validate_only, "validateOnly"
  end
end
