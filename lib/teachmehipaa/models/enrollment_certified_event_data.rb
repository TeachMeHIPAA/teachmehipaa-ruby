# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An EnrollmentCertifiedEventData object.
  class EnrollmentCertifiedEventData < Model
    field :subject_id, "subjectId"
    field :course_id, "courseId"
    field :enrollment_id, "enrollmentId"
  end
end
