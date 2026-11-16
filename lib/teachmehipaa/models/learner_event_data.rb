# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnerEventData object.
  class LearnerEventData < Model
    # @return [String]
    field :learner_id, "learnerId"
    # @return [String]
    field :email, "email"
    # @return [String, nil]
    field :external_id, "externalId"
    # @return [String]
    field :course_id, "courseId"
    # See LearnerStatus for known values; the API may send newer ones.
    #
    # @return [String]
    field :status, "status"
    # @return [Time]
    field :occurred_at, "occurredAt", type: :time
  end
end
