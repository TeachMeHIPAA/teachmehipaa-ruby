# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnersExportRequest object.
  class LearnersExportRequest < Model
    # The file format. Only `csv` today.
    #
    # See LearnersExportRequestFormat for known values; the API may send newer ones.
    #
    # @return [String]
    field :format, "format"
    # The course to export. Defaults to the organization's default course.
    #
    # @return [String, nil]
    field :course_id, "courseId"
    # Only export learners with this status.
    #
    # See LearnerStatus for known values; the API may send newer ones.
    #
    # @return [String, nil]
    field :status, "status"
  end
end
