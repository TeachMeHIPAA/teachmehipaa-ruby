# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "learner_certificate"
require_relative "learner_course"

module TeachMeHipaa
  # A Learner object.
  class Learner < Model
    # Unique identifier for the learner. The same as the member's `subjectId`.
    field :learner_id, "learnerId"
    # The learner's email address.
    field :email, "email"
    # The learner's full name.
    field :name, "name"
    # Your own id for the learner, unique within the organization.
    field :external_id, "externalId"
    # The learner's training status in this course. One of `not_started` (invited),
    # `invite_bounced`, `in_progress`, `compliant`, `expiring_soon` (within 60 days of expiry),
    # `expired` or `removed`.
    #
    # See LearnerStatus for known values; the API may send newer ones.
    field :status, "status"
    # The course this learner record is for.
    field :course, "course", type: LearnerCourse
    # When the learner was invited (ISO 8601).
    field :invited_at, "invitedAt", type: :time
    # When the learner started training.
    field :started_at, "startedAt", type: :time
    # When the learner completed the course.
    field :completed_at, "completedAt", type: :time
    # When the learner's training is due.
    field :due_at, "dueAt", type: :time
    # The learner's current certificate, with its verification and PDF links.
    field :certificate, "certificate", type: LearnerCertificate
  end
end
