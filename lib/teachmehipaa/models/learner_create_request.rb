# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnerCreateRequest object.
  class LearnerCreateRequest < Model
    # The learner's email address.
    field :email, "email"
    # The learner's full name.
    field :name, "name"
    # Your own id for the learner, unique within the organization.
    field :external_id, "externalId"
    # The course to invite them to. Defaults to the organization's default course.
    field :course_id, "courseId"
    # `email` (default) sends the invite email. `none` sends nothing and returns `joinUrl` for you
    # to deliver.
    #
    # See LearnerCreateRequestDelivery for known values; the API may send newer ones.
    field :delivery, "delivery"
    # `require_available` fails with `409` when no seat is free.
    #
    # See LearnerCreateRequestSeatPolicy for known values; the API may send newer ones.
    field :seat_policy, "seatPolicy"
  end
end
