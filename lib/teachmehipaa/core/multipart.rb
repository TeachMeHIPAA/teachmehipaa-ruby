# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # Encodes a multipart/form-data body: the IR's binary parts as files
    # with their content type, every other field as a JSON part (the spec's
    # +encoding+ for them).
    #
    # @api private
    module Multipart
      module_function

      # +body+ is wire-named fields; a binary field's value is a String of
      # bytes or an IO-like object answering +read+. +binary_parts+ maps a
      # field name to its content type. Returns the body and its
      # Content-Type.
      def encode(body, binary_parts)
        boundary = "teachmehipaa-#{SecureRandom.hex(16)}"
        parts = body.compact.map do |name, value|
          content_type = binary_parts[name]
          content_type ? file_part(name, value, content_type) : json_part(name, value)
        end
        encoded = parts.map { |part| "--#{boundary}\r\n".b << part << "\r\n" }.join.b << "--#{boundary}--\r\n"
        [encoded, "multipart/form-data; boundary=#{boundary}"]
      end

      def file_part(name, value, content_type)
        filename = value.respond_to?(:path) ? File.basename(value.path) : name
        data = value.respond_to?(:read) ? value.read : value
        raise ArgumentError, "#{name} must be a String of bytes or an IO, not #{value.class}" unless data.is_a?(String)

        "Content-Disposition: form-data; name=\"#{name}\"; filename=\"#{filename}\"\r\n" \
        "Content-Type: #{content_type}\r\n\r\n".b << data.b
      end

      def json_part(name, value)
        "Content-Disposition: form-data; name=\"#{name}\"\r\n" \
        "Content-Type: application/json\r\n\r\n#{JSON.generate(value)}".b
      end
    end
  end
end
