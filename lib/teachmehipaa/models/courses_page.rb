# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "course"

module TeachMeHipaa
  # A CoursesPage object.
  class CoursesPage < Model
    field :items, "items", type: [Course]
    field :next_cursor, "nextCursor"
  end
end
