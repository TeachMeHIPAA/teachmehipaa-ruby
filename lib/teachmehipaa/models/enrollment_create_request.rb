# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An EnrollmentCreateRequest object.
  class EnrollmentCreateRequest < Model
    # The learner's email address.
    field :email, "email"
    # The learner's full name.
    field :name, "name"
    # The course to invite them to. Defaults to `hipaa`.
    field :course_id, "courseId"
  end
end
