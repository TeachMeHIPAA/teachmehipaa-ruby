# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnerRemindAccepted object.
  class LearnerRemindAccepted < Model
    # The learner the reminder is for.
    field :learner_id, "learnerId"
    # Always `remind`.
    #
    # See LearnerRemindAcceptedAction for known values; the API may send newer ones.
    field :action, "action"
  end
end
