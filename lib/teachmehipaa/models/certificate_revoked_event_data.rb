# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A CertificateRevokedEventData object.
  class CertificateRevokedEventData < Model
    field :certificate_id, "certificateId"
    field :learner_id, "learnerId"
    field :course_id, "courseId"
  end
end
