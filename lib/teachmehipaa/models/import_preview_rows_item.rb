# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # An ImportPreviewRowsItem object.
  class ImportPreviewRowsItem < Model
    field :row_number, "rowNumber"
    field :email, "email"
    field :name, "name"
    field :course_id, "courseId"
    # See ImportPreviewRowsItemStatus for known values; the API may send newer ones.
    field :status, "status"
    field :detail, "detail"
  end
end
