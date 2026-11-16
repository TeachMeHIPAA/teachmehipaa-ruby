# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnerLaunchLink object.
  class LearnerLaunchLink < Model
    # The single-use sign-in URL. Redirect the learner to it right away.
    #
    # @return [String]
    field :url, "url"
    # When the URL stops working, 5 minutes after it was created.
    #
    # @return [Time]
    field :expires_at, "expiresAt", type: :time
  end
end
