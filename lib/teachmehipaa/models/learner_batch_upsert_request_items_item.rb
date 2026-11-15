# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnerBatchUpsertRequestItemsItem object.
  class LearnerBatchUpsertRequestItemsItem < Model
    field :email, "email"
    field :name, "name"
    field :external_id, "externalId"
    field :course_id, "courseId"
  end
end
