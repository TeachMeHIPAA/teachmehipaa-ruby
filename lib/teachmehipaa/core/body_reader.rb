# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # Reads one response body for a download given a block: a success of the
    # promised type goes to the block chunk by chunk; anything else (an
    # error to map, say) is read whole.
    #
    # @api private
    class BodyReader
      # The response read, once the transport has streamed it.
      attr_reader :response

      # +stream+ receives the status and lower-cased headers, and returns the
      # block for the chunks, or nil to read the body whole.
      def initialize(stream)
        @stream = stream
        @started = false
        @block_failed = false
      end

      # Whether any chunk reached the block: from then on the call can't be
      # replayed without handing the block those bytes twice.
      def started? = @started

      # Whether the block itself raised, so the error is the caller's own.
      def block_failed? = @block_failed

      # +response+'s body is a String, or chunks answering +each+.
      def read(response)
        headers = response.headers.to_h { |name, value| [name.to_s.downcase, value] }
        block = @stream.call(response.status, headers)
        chunks = response.body.is_a?(String) ? [response.body] : response.body
        body = block ? deliver(chunks, block) : chunks.each_with_object(+"".b) { |chunk, all| all << chunk }
        @response = Transport::Response.new(status: response.status, headers:, body:)
      end

      private

      def deliver(chunks, block)
        chunks.each do |chunk|
          next if chunk.empty?

          @started = true
          begin
            block.call(chunk.b)
          rescue StandardError
            @block_failed = true
            raise
          end
        end
        ""
      end
    end
  end
end
