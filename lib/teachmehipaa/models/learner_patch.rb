# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnerPatch object.
  #
  # Sent as a JSON merge patch: leave a field out to keep it; nil clears a nullable field.
  class LearnerPatch < Model
    # The learner's full name.
    #
    # @return [String, nil]
    field :name, "name"
    # Your own id for the learner. Set it to `null` to clear it.
    #
    # @return [String, nil]
    field :external_id, "externalId"
  end
end
