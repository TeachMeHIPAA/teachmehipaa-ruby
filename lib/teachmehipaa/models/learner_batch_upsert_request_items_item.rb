# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnerBatchUpsertRequestItemsItem object.
  class LearnerBatchUpsertRequestItemsItem < Model
    # @return [String]
    field :email, "email"
    # @return [String, nil]
    field :name, "name"
    # @return [String, nil]
    field :external_id, "externalId"
    # @return [String, nil]
    field :course_id, "courseId"
  end
end
