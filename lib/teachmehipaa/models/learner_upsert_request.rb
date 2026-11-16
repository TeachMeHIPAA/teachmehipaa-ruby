# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # A LearnerUpsertRequest object.
  class LearnerUpsertRequest < Model
    # The learner's email address.
    #
    # @return [String]
    field :email, "email"
    # The learner's full name.
    #
    # @return [String, nil]
    field :name, "name"
    # The course to invite them to. Defaults to the organization's default course.
    #
    # @return [String, nil]
    field :course_id, "courseId"
    # `email` (default) sends the invite email. `none` sends nothing and returns `joinUrl` for you
    # to deliver.
    #
    # See LearnerUpsertRequestDelivery for known values; the API may send newer ones.
    #
    # @return [String, nil]
    field :delivery, "delivery"
    # `require_available` fails with `409` when no seat is free.
    #
    # See LearnerUpsertRequestSeatPolicy for known values; the API may send newer ones.
    #
    # @return [String, nil]
    field :seat_policy, "seatPolicy"
  end
end
