# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module TokenIntrospectionScopesItem
    ME = "me"
    ENROLLMENTS_READ = "enrollments:read"
    ENROLLMENTS_WRITE = "enrollments:write"
    MEMBERS_READ = "members:read"
    MEMBERS_ADMIN = "members:admin"
    CERTIFICATES_READ = "certificates:read"
    CERTIFICATES_WRITE = "certificates:write"
    BILLING_WRITE = "billing:write"
    ORG_ADMIN = "org:admin"
    AUDIT_READ = "audit:read"
    SCIM = "scim"
    SUPPORT_WRITE = "support:write"
    LEARNERS_READ = "learners:read"
    LEARNERS_WRITE = "learners:write"
    COMPLIANCE_READ = "compliance:read"
    WEBHOOKS_MANAGE = "webhooks:manage"
  end
end
