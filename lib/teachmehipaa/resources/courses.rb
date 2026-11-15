# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.courses+.
    class Courses < Core::Resource
      # List all courses
      #
      # Returns a list of the courses in the public catalog. Needs no access token.
      def list(limit: nil, cursor: nil, request_options: {})
        request(
          method: "GET",
          path: "/courses",
          query: { limit:, cursor: },
          retry_safe: true,
          response: :page,
          model: Course,
          pagination: { style: :cursor, cursor_param: "cursor" },
          request_options:,
        )
      end

      # Retrieve a course
      #
      # Retrieves a course from the public catalog.
      #
      # Given +if_none_match:+ (an ETag, or the copy you hold), returns NotModified when your copy
      # is current.
      def retrieve(course_id, if_none_match: nil, request_options: {})
        request(
          method: "GET",
          path: "/courses/{courseId}",
          path_params: { courseId: course_id },
          if_none_match:,
          retry_safe: true,
          model: Course,
          request_options:,
        )
      end
    end
  end
end
