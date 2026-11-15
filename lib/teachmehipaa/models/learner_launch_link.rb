# frozen_string_literal: true

# Hand-written for the tracer; the generator replaces this file.
module TeachMeHipaa
  # A single-use Launch link; redirect the Learner to #url right away.
  class LearnerLaunchLink < Model
    field :url, "url"
    field :expires_at, "expiresAt", type: :time
  end
end
