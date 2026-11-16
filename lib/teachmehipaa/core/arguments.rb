# frozen_string_literal: true

module TeachMeHipaa
  # The library's internals, which may change in any release. The API
  # reference leaves them out.
  #
  # @api private
  module Core
    # Checks on the arguments the library is given.
    #
    # @api private
    module Arguments
      module_function

      # Whether +value+ is a String with more than whitespace in it, as every
      # id, secret and token the library sends must be.
      def text?(value)
        value.is_a?(String) && !value.strip.empty?
      end
    end
  end
end
