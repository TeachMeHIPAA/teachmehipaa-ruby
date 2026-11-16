# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An EnrollmentCreateRequest object.
  class EnrollmentCreateRequest < Model
    # The learner's email address.
    #
    # @return [String]
    field :email, "email"
    # The learner's full name.
    #
    # @return [String, nil]
    field :name, "name"
    # The course to invite them to. Defaults to `hipaa`.
    #
    # @return [String, nil]
    field :course_id, "courseId"
  end
end
