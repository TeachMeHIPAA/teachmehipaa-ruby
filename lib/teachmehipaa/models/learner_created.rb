# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "learner_created_certificate"
require_relative "learner_created_course"

module TeachMeHipaa
  # A LearnerCreated object.
  class LearnerCreated < Model
    # Unique identifier for the learner.
    #
    # @return [String]
    field :learner_id, "learnerId"
    # The learner's email address.
    #
    # @return [String]
    field :email, "email"
    # The learner's full name.
    #
    # @return [String, nil]
    field :name, "name"
    # Your own id for the learner.
    #
    # @return [String, nil]
    field :external_id, "externalId"
    # The learner's training status. One of `not_started` (invited), `invite_bounced`,
    # `in_progress`, `compliant`, `expiring_soon` (within 60 days of expiry), `expired` or
    # `removed`.
    #
    # See LearnerStatus for known values; the API may send newer ones.
    #
    # @return [String]
    field :status, "status"
    # The course the learner was invited to.
    #
    # @return [LearnerCreatedCourse]
    field :course, "course", type: LearnerCreatedCourse
    # @return [Time, nil]
    field :invited_at, "invitedAt", type: :time
    # @return [Time, nil]
    field :started_at, "startedAt", type: :time
    # @return [Time, nil]
    field :completed_at, "completedAt", type: :time
    # @return [Time, nil]
    field :due_at, "dueAt", type: :time
    # @return [LearnerCreatedCertificate, nil]
    field :certificate, "certificate", type: LearnerCreatedCertificate
    # How the invite was delivered: `email`, or `none` when you deliver it.
    #
    # See LearnerCreatedDelivery for known values; the API may send newer ones.
    #
    # @return [String, nil]
    field :delivery, "delivery"
    # The invite link, returned once when `delivery` is `none`. Send it to the learner yourself.
    #
    # @return [String, nil]
    field :join_url, "joinUrl"
  end
end
