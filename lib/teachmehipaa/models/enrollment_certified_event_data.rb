# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An EnrollmentCertifiedEventData object.
  class EnrollmentCertifiedEventData < Model
    # @return [String]
    field :subject_id, "subjectId"
    # @return [String]
    field :course_id, "courseId"
    # @return [String, nil]
    field :enrollment_id, "enrollmentId"
  end
end
