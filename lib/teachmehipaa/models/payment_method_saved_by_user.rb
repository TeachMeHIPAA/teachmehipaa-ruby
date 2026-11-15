# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

require_relative "payment_method_saved_by"

module TeachMeHipaa
  # A PaymentMethodSavedByUser object.
  class PaymentMethodSavedByUser < Model
    include PaymentMethodSavedBy

    field :type, "type"
    field :name, "name"
  end
end
