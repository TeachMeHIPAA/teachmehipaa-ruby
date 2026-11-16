# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A MemberListItem object.
  class MemberListItem < Model
    # @return [String, nil]
    field :subject_id, "subjectId"
    # @return [String]
    field :email, "email"
    # @return [String, nil]
    field :name, "name"
    # See MemberListItemRole for known values; the API may send newer ones.
    #
    # @return [String]
    field :role, "role"
    # @return [Boolean]
    field :is_disabled, "isDisabled"
    # @return [String, nil]
    field :enrollment_subject_id, "enrollmentSubjectId"
    # @return [Boolean, nil]
    field :holds_invitation, "holdsInvitation"
  end
end
