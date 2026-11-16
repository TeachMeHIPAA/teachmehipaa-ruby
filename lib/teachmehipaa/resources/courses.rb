# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  module Resources
    # The methods under +client.courses+.
    class Courses < Core::Resource
      # List all courses
      #
      # Returns a list of the courses in the public catalog. Needs no access token.
      #
      # Sends no Access token, so it also works on a client built without credentials.
      #
      # @param limit [Integer, nil] How many objects to return, between 1 and 100. Defaults to 20.
      # @param cursor [String, nil] The `nextCursor` from the previous page.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Page<Course>]
      def list(limit: nil, cursor: nil, request_options: {})
        request(
          method: "GET",
          path: "/courses",
          query: { limit:, cursor: },
          retry_safe: true,
          authenticated: false,
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
      #
      # Sends no Access token, so it also works on a client built without credentials.
      #
      # @param course_id [String]
      # @param if_none_match [String, Model] The ETag of the copy you hold: a String, or the
      #   object you read.
      # @param request_options [Hash] Options for this call only: +idempotency_key+,
      #   +max_retries+, +timeout+, +request_id+ and +headers+.
      # @return [Course, NotModified]
      def retrieve(course_id, if_none_match: nil, request_options: {})
        request(
          method: "GET",
          path: "/courses/{courseId}",
          path_params: { courseId: course_id },
          if_none_match:,
          retry_safe: true,
          authenticated: false,
          model: Course,
          request_options:,
        )
      end
    end
  end
end
