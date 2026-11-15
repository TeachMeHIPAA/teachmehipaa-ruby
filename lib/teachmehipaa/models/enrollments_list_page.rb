# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "org_enrollment_list_item"

module TeachMeHipaa
  # An EnrollmentsListPage object.
  class EnrollmentsListPage < Model
    field :items, "items", type: [OrgEnrollmentListItem]
    field :next_cursor, "nextCursor"
  end
end
