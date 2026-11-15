# frozen_string_literal: true

# Hand-written for the tracer; the generator replaces this file.
module TeachMeHipaa
  module Resources
    # The resource accessors on TeachMeHipaa::Client.
    module Root
      attr_reader :learners

      private

      def build_resources(requestor)
        @learners = Learners.new(requestor)
      end
    end
  end
end
