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

      # +body+ with a value the method sets itself (an IR const constraint,
      # such as previewImport's validateOnly) written at +path+.
      def fixed(body, (key, *rest), value)
        body.merge(key => rest.empty? ? value : fixed(body[key] || {}, rest, value))
      end
    end
  end
end
