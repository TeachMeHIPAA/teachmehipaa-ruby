# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # Base class for resource classes (client.learners and its siblings).
    #
    # @api private
    class Resource
      def initialize(requestor)
        @requestor = requestor
      end

      def inspect
        "#<#{self.class.name}>"
      end

      private

      def request(...)
        @requestor.request(...)
      end
    end
  end
end
