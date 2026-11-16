# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "learner_batch_upsert_request_items_item"

module TeachMeHipaa
  # A LearnerBatchUpsertRequest object.
  class LearnerBatchUpsertRequest < Model
    # Up to 500 learners, each with the same fields as creating one learner.
    #
    # @return [Array<LearnerBatchUpsertRequestItemsItem>]
    field :items, "items", type: [LearnerBatchUpsertRequestItemsItem]
    # Applies to every item. `email` (default) sends invites; `none` sends nothing.
    #
    # See LearnerBatchUpsertRequestDelivery for known values; the API may send newer ones.
    #
    # @return [String, nil]
    field :delivery, "delivery"
    # Applies to every item. `require_available` fails an item when no seat is free.
    #
    # See LearnerBatchUpsertRequestSeatPolicy for known values; the API may send newer ones.
    #
    # @return [String, nil]
    field :seat_policy, "seatPolicy"
  end
end
