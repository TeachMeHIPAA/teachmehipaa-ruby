# frozen_string_literal: true

module TeachMeHipaa
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

      def require_text(value, name)
        return value if text?(value)

        raise ArgumentError, "#{name} must be a non-empty String"
      end
    end
  end
end
