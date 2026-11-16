# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A machine-readable error code, such as `seat_unavailable`.
  #
  # Known values; the API may add more at any time, so handle values you don't recognize.
  module ProblemCode
    VALIDATION_FAILED = "validation_failed"
    UNAUTHORIZED = "unauthorized"
    FORBIDDEN = "forbidden"
    NOT_FOUND = "not_found"
    METHOD_NOT_ALLOWED = "method_not_allowed"
    NOT_ACCEPTABLE = "not_acceptable"
    CONFLICT = "conflict"
    RATE_LIMITED = "rate_limited"
    PRECONDITION_REQUIRED = "precondition_required"
    PRECONDITION_FAILED = "precondition_failed"
    IDEMPOTENCY_KEY_REUSE = "idempotency_key_reuse"
    UNSUPPORTED_MEDIA_TYPE = "unsupported_media_type"
    ILLEGAL_TRANSITION = "illegal_transition"
    SEAT_UNAVAILABLE = "seat_unavailable"
    SEAT_ALREADY_CLAIMED = "seat_already_claimed"
    ALREADY_INVITED = "already_invited"
    EMAIL_ALREADY_REGISTERED = "email_already_registered"
    LAST_ADMIN_REMOVAL_BLOCKED = "last_admin_removal_blocked"
    ORG_NOT_ACTIVE = "org_not_active"
    ENROLLMENT_ARCHIVED = "enrollment_archived"
    LESSONS_INCOMPLETE = "lessons_incomplete"
    BATCH_TOO_LARGE = "batch_too_large"
    IMPORT_TOO_LARGE = "import_too_large"
    EXPORT_TOO_LARGE = "export_too_large"
    SUMMARY_TOO_LARGE = "summary_too_large"
    SEAT_NOT_REFUNDABLE = "seat_not_refundable"
    REFUND_FAILED = "refund_failed"
    NOT_CONFIGURED = "not_configured"
    RESET_UNAVAILABLE = "reset_unavailable"
    AUTO_RECERTIFY_UNAVAILABLE = "auto_recertify_unavailable"
    API_CLIENT_LIMIT_REACHED = "api_client_limit_reached"
    EXTERNAL_ID_CONFLICT = "external_id_conflict"
    CANNOT_OFFBOARD_ADMIN = "cannot_offboard_admin"
    CANNOT_LAUNCH_ADMIN = "cannot_launch_admin"
    LEARNER_REMOVED = "learner_removed"
    LEARNER_NOT_ACCEPTED = "learner_not_accepted"
    CANNOT_RENAME_ADMIN = "cannot_rename_admin"
    LEARNER_IN_MULTIPLE_ORGS = "learner_in_multiple_orgs"
    ACCOUNT_EXISTS_USE_SIGN_IN = "account_exists_use_sign_in"
    NAME_CHANGE_NOT_ALLOWED = "name_change_not_allowed"
    TEMPORARILY_UNAVAILABLE = "temporarily_unavailable"
  end
end
