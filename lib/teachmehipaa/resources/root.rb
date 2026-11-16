# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The resource accessors on TeachMeHipaa::Client.
    module Root
      attr_reader :audit_events, :auth, :certificate_verifications, :certificates, :compliance, :courses, :enrollments,
                  :events, :learners, :members, :operations, :seats, :webhook_subscriptions

      private

      def build_resources(requestor)
        @audit_events = AuditEvents.new(requestor)
        @auth = Auth.new(requestor)
        @certificate_verifications = CertificateVerifications.new(requestor)
        @certificates = Certificates.new(requestor)
        @compliance = Compliance.new(requestor)
        @courses = Courses.new(requestor)
        @enrollments = Enrollments.new(requestor)
        @events = Events.new(requestor)
        @learners = Learners.new(requestor)
        @members = Members.new(requestor)
        @operations = Operations.new(requestor)
        @seats = Seats.new(requestor)
        @webhook_subscriptions = WebhookSubscriptions.new(requestor)
      end
    end
  end
end
