# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "member_list_item"

module TeachMeHipaa
  # A MembersPage object.
  class MembersPage < Model
    # @return [Array<MemberListItem>]
    field :items, "items", type: [MemberListItem]
    # @return [String, nil]
    field :next_cursor, "nextCursor"
  end
end
