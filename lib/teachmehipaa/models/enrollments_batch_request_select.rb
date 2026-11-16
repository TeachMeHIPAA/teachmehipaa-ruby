# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # The enrollments to act on: a list of `enrollmentIds` (up to 500), or a `filter`.
  #
  # The variant is picked by which field is present.
  module EnrollmentsBatchRequestSelect
    extend Union

    # An EnrollmentsBatchRequestSelect this library doesn't know yet. Its fields are all kept; read
    # them with #[] or #to_h.
    class Unknown < Model
      include EnrollmentsBatchRequestSelect
    end

    variants(
      {
        "enrollmentIds" => "EnrollmentsBatchRequestSelectEnrollmentIds",
        "filter" => "EnrollmentsBatchRequestSelectFilter",
      },
      fallback: "EnrollmentsBatchRequestSelect::Unknown",
    )
  end
end
