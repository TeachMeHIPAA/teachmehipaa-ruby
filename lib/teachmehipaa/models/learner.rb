# frozen_string_literal: true

# Hand-written for the tracer; the generator replaces this file.
module TeachMeHipaa
  # A Member taking a Training, seen from the Organization's side.
  class Learner < Model
    # Known values of #status. The API may add more.
    module Status
      NOT_STARTED = "not_started"
      INVITE_BOUNCED = "invite_bounced"
      IN_PROGRESS = "in_progress"
      COMPLIANT = "compliant"
      EXPIRING_SOON = "expiring_soon"
      EXPIRED = "expired"
      REMOVED = "removed"
    end

    # The Course this Learner record is for.
    class Course < Model
      field :course_id, "courseId"
      field :title, "title"
    end

    # The Learner's current Certificate, with its verification and PDF links.
    class Certificate < Model
      field :certificate_id, "certificateId"
      field :issued_at, "issuedAt", type: :time
      field :expires_at, "expiresAt", type: :time
      field :verify_url, "verifyUrl"
      field :pdf_url, "pdfUrl"
    end

    field :learner_id, "learnerId"
    field :email, "email"
    field :name, "name"
    field :external_id, "externalId"
    field :status, "status"
    field :course, "course", type: Course
    field :invited_at, "invitedAt", type: :time
    field :started_at, "startedAt", type: :time
    field :completed_at, "completedAt", type: :time
    field :due_at, "dueAt", type: :time
    field :certificate, "certificate", type: Certificate
  end
end
