# frozen_string_literal: true

module SdkGenerator
  # What each operation's API-reference sample passes and does with the
  # result. CodeSamples builds the client and the call around it from the
  # IR, and checks every keyword here against the method's parameters.
  #
  # +result+ names the call's return value, +args+ are its keywords (path
  # parameters come from PATH_VALUES), +before+ is source that runs first,
  # and +use+ is the line that does something with the result. The values
  # match the samples of the other TeachMeHIPAA libraries, so the API
  # reference shows the same call in every language.
  module SampleCalls
    # Ruby source to emit as is, such as a local variable.
    Raw = Data.define(:source)

    LEARNER_ID = "sub_01JD80AB2C3D4E5F6G7H8J9K0M"
    ENROLLMENT_ID = "enr_01JD8K2M4N6P8Q0R2S4T6V8W0X"
    EMAIL = "dana.whitfield@example.com"
    NAME = "Dana Whitfield"
    COURSE_ID = "hipaa-2026"
    WEBHOOK_URL = "https://example.com/webhooks/teachmehipaa"

    PATH_VALUES = {
      "learnerId" => LEARNER_ID,
      "subjectId" => LEARNER_ID,
      "enrollmentId" => ENROLLMENT_ID,
      "certId" => "cert_01JD8F3G5H7J9K1M3N5P7Q9R1S",
      "courseId" => COURSE_ID,
      "externalId" => "hr-1042",
      "operationId" => "op_01JD8T4V6W8X0Y2Z4A6B8C0D2E",
      "subscriptionId" => "whs_01JD8Q5R7S9T1V3W5X7Y9Z1A3B",
      "tinyId" => "a7Kq2Z",
    }.freeze

    def self.call(result, use, args: {}, before: nil, chain: nil)
      { result:, args:, before:, chain:, use: }.freeze
    end

    # An export waits on its Operation and saves the CSV it holds.
    def self.export(fallback_name, **args)
      call("export", "File.write(export.filename || \"#{fallback_name}.csv\", export.csv)",
           args: { format: "csv", **args }, chain: ".wait.export_result")
    end

    CALLS = {
      "listAuditEvents" => call("events", 'events.auto_paging_each { |event| puts "#{event.at} #{event.type}" }'),
      "introspectAccessToken" => call("token", 'puts token.scopes.join(" ")'),
      "getCertificateVerification" => call("verification", "puts verification.status"),
      "downloadCertificatePdf" => call("pdf", 'File.binwrite(pdf.filename || "certificate.pdf", pdf.data)'),
      "exportCertificates" => export("certificates"),
      "listCertificates" => call("certificates", "certificates.auto_paging_each { |cert| puts cert.expires_at }",
                                 args: { subject_id: LEARNER_ID }),
      "getCertificate" => call("certificate", 'puts "#{certificate.status}, expires #{certificate.expires_at}"'),
      "getCertificateCredentials" => call("links", "puts links.short_link"),
      "getComplianceSummary" => call("summary", 'puts "#{(summary.compliant_rate * 100).round}% compliant"',
                                     args: { course_id: COURSE_ID }),
      "listCourses" => call("courses", "courses.auto_paging_each { |course| puts course.title }"),
      "getCourse" => call("course", "puts course.title"),
      "batchEnrollments" => call(
        "batch", 'batch.results.each { |row| puts "#{row.enrollment_id}: #{row.outcome}" }',
        args: { operation: "remind", select: { enrollment_ids: [ENROLLMENT_ID] } }
      ),
      "cancelEnrollment" => call("enrollment", "puts enrollment.status", args: { refund: true }),
      "createEnrollment" => call("enrollment", "puts enrollment.enrollment_id",
                                 args: { email: EMAIL, course_id: COURSE_ID }),
      "exportEnrollments" => export("enrollments"),
      "importEnrollments" => call("operation", "puts operation.wait.done",
                                  args: { file: "roster.csv", options: { course_id: COURSE_ID } }),
      "listEnrollments" => call("enrollments", "enrollments.auto_paging_each { |e| puts e.enrollment_id }",
                                args: { course_id: COURSE_ID }),
      "remindEnrollment" => call("reminder", "puts reminder.action"),
      "renewEnrollment" => call("enrollment", "puts enrollment.cycle"),
      "resendEnrollmentInvite" => call("resent", "puts resent.action"),
      "getEnrollment" => call("enrollment", "puts enrollment.effective_status"),
      "listOrgEvents" => call("events", "events.auto_paging_each { |event| puts event.event_id }",
                              args: { type: "learner.certified" }),
      "batchUpsertLearners" => call("operation", "puts operation.wait.done",
                                    args: { items: [{ email: EMAIL, name: NAME, external_id: "hr-1042" }] }),
      "createLearner" => call("learner", 'puts learner.created? ? "Invited #{learner.email}" : "Already enrolled"',
                              args: { email: EMAIL, name: NAME }),
      "createLearnerLaunchLink" => call("link", "puts link.url"),
      "exportLearners" => export("learners"),
      "listLearners" => call("learners", "learners.auto_paging_each { |learner| puts learner.email }",
                             args: { status: "in_progress" }),
      "offboardLearner" => call("learner", "puts learner.status"),
      "remindLearner" => call("reminder", "puts reminder.action"),
      "getLearner" => call("learner", 'puts "#{learner.name}: #{learner.status}"'),
      "updateLearner" => call("learner", "puts learner.name",
                              before: "current = client.learners.retrieve(#{LEARNER_ID.inspect})",
                              args: { if_match: Raw.new("current"), name: NAME }),
      "upsertLearnerByExternalId" => call("learner", 'puts learner.created? ? "Invited" : "Already enrolled"',
                                          args: { email: EMAIL, name: NAME }),
      "listMembers" => call("members", "members.auto_paging_each { |member| puts member.email }",
                            args: { role: "admin" }),
      "getMember" => call("member", 'puts "#{member.name} (#{member.role})"'),
      "getOperation" => call("operation", "puts operation.done"),
      "getSeatInventory" => call("seats", 'puts "#{seats.available} of #{seats.total} Seats free"'),
      "createWebhookSubscription" => call("subscription", "puts subscription.secret",
                                          args: { endpoint_url: WEBHOOK_URL, event_types: ["learner.certified"] }),
      "deleteWebhookSubscription" => call("deleted", "puts deleted.last_response.status"),
      "listWebhookSubscriptions" => call("subscriptions",
                                         "subscriptions.auto_paging_each { |sub| puts sub.endpoint_url }"),
      "redriveWebhookSubscription" => call("operation", "puts operation.wait.response.tag"),
      "getWebhookSubscription" => call("subscription", "puts subscription.enabled"),
      "testWebhookSubscription" => call("operation", "puts operation.wait.response.tag"),
      "updateWebhookSubscription" => call(
        "subscription", "puts subscription.enabled",
        before: "current = client.webhook_subscriptions.retrieve(#{PATH_VALUES.fetch("subscriptionId").inspect})",
        args: { if_match: Raw.new("current"), enabled: false }
      ),
    }.freeze
  end
end
