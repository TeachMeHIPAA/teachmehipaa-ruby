# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A CertificateRevokedEventData object.
  class CertificateRevokedEventData < Model
    # @return [String]
    field :certificate_id, "certificateId"
    # @return [String]
    field :learner_id, "learnerId"
    # @return [String]
    field :course_id, "courseId"
  end
end
