# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A MemberListItem object.
  class MemberListItem < Model
    field :subject_id, "subjectId"
    field :email, "email"
    field :name, "name"
    # See MemberListItemRole for known values; the API may send newer ones.
    field :role, "role"
    field :is_disabled, "isDisabled"
    field :enrollment_subject_id, "enrollmentSubjectId"
    field :holds_invitation, "holdsInvitation"
  end
end
