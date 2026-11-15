# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A Member object.
  class Member < Model
    # Unique identifier for the member. `null` for an older member who can't be addressed yet.
    field :subject_id, "subjectId"
    # The member's email address.
    field :email, "email"
    # The member's full name.
    field :name, "name"
    # `admin` or `learner`.
    #
    # See MemberRole for known values; the API may send newer ones.
    field :role, "role"
    # Whether the member's account is disabled.
    field :is_disabled, "isDisabled"
  end
end
