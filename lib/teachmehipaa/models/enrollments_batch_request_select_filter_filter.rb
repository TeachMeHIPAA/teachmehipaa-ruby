# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An EnrollmentsBatchRequestSelectFilterFilter object.
  class EnrollmentsBatchRequestSelectFilterFilter < Model
    # See EnrollmentsBatchRequestSelectFilterFilterStatus for known values; the API may send newer
    # ones.
    #
    # @return [String, nil]
    field :status, "status"
    # @return [String, nil]
    field :course_id, "courseId"
    # @return [Boolean, nil]
    field :archived, "archived"
  end
end
