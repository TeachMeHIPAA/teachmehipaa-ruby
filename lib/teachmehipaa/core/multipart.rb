# frozen_string_literal: true

module TeachMeHipaa
  # File content given as bytes, for an upload such as an Enrollment
  # import's CSV. A String passed as the file itself is always a path, so
  # wrap CSV text you already hold:
  #
  #   client.enrollments.preview_import(file: TeachMeHipaa::FilePart.new(csv, filename: "roster.csv"))
  #
  # Without +filename+, the part is named after its field (+file.csv+).
  class FilePart
    attr_reader :data, :filename

    def initialize(data, filename: nil)
      raise ArgumentError, "FilePart data must be a String, not #{data.class}" unless data.is_a?(String)

      @data = data.b.freeze
      @filename = filename
      freeze
    end

    # The bytes stay out of inspect output: a roster holds people's names.
    def inspect
      "#<#{self.class.name} filename=#{filename.inspect} bytes=#{data.bytesize}>"
    end
  end

  module Core
    # Encodes a multipart/form-data body: the IR's binary parts as files
    # with their content type, every other field as a JSON part (the spec's
    # +encoding+ for them).
    #
    # @api private
    module Multipart
      # The default filename's extension, by a binary part's content type.
      EXTENSIONS = { "text/csv" => ".csv" }.freeze

      module_function

      # +body+ is wire-named fields; a binary field's value is a path (a
      # String or Pathname), an IO-like object answering +read+, or a
      # FilePart. Each file is read here, once per call, so every retry
      # sends the same bytes even from a stream. +binary_parts+ maps a field
      # name to its content type. Returns the body and its Content-Type.
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
        filename, data = read_file(name, value, "#{name}#{EXTENSIONS[content_type]}")
        "Content-Disposition: form-data; name=\"#{name}\"; filename=\"#{filename}\"\r\n" \
        "Content-Type: #{content_type}\r\n\r\n".b << data.b
      end

      # [filename, bytes] for a binary field's value.
      def read_file(name, value, default_filename)
        return [value.filename || default_filename, value.data] if value.is_a?(FilePart)
        # Before the IO check: a Pathname answers +read+ too.
        return read_path(name, value.to_s) if value.is_a?(String) || value.is_a?(Pathname)
        return read_io(name, value, default_filename) if value.respond_to?(:read)

        raise ArgumentError, "#{name} must be a path, an IO or a TeachMeHipaa::FilePart, not #{value.class}"
      end

      # A path never holds a line break; CSV text always does.
      def read_path(name, path)
        if path.match?(/[\r\n]/)
          raise ArgumentError, "#{name} was given text, but a String is a file path. Pass content you hold " \
                               "as TeachMeHipaa::FilePart.new(text) or a StringIO."
        end

        [File.basename(path), File.binread(path)]
      end

      def read_io(name, io, default_filename)
        data = io.read
        raise ArgumentError, "#{name}: #{io.class}#read returned #{data.class}, not a String" unless data.is_a?(String)

        path = io.respond_to?(:path) ? io.path : nil
        [path.is_a?(String) ? File.basename(path) : default_filename, data]
      end

      def json_part(name, value)
        "Content-Disposition: form-data; name=\"#{name}\"\r\n" \
        "Content-Type: application/json\r\n\r\n#{JSON.generate(value)}".b
      end
    end
  end
end
