# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An ImportPreviewRowsItem object.
  class ImportPreviewRowsItem < Model
    # @return [Integer]
    field :row_number, "rowNumber"
    # @return [String]
    field :email, "email"
    # @return [String, nil]
    field :name, "name"
    # @return [String]
    field :course_id, "courseId"
    # See ImportPreviewRowsItemStatus for known values; the API may send newer ones.
    #
    # @return [String]
    field :status, "status"
    # @return [String, nil]
    field :detail, "detail"
  end
end
