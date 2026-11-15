# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "member_list_item"

module TeachMeHipaa
  # A MembersPage object.
  class MembersPage < Model
    field :items, "items", type: [MemberListItem]
    field :next_cursor, "nextCursor"
  end
end
