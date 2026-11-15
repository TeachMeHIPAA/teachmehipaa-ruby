# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnerEventData object.
  class LearnerEventData < Model
    field :learner_id, "learnerId"
    field :email, "email"
    field :external_id, "externalId"
    field :course_id, "courseId"
    # See LearnerStatus for known values; the API may send newer ones.
    field :status, "status"
    field :occurred_at, "occurredAt", type: :time
  end
end
