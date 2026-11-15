# frozen_string_literal: true

# Hand-written for the tracer; the generator replaces this file.
module TeachMeHipaa
  # A reminder to a Learner was queued.
  class LearnerRemindAccepted < Model
    # Known values of #action. The API may add more.
    module Action
      REMIND = "remind"
    end

    field :learner_id, "learnerId"
    field :action, "action"
  end
end
