# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An EnrollmentsBatchRequestSelectFilterFilter object.
  class EnrollmentsBatchRequestSelectFilterFilter < Model
    # See EnrollmentsBatchRequestSelectFilterFilterStatus for known values; the API may send newer
    # ones.
    field :status, "status"
    field :course_id, "courseId"
    field :archived, "archived"
  end
end
