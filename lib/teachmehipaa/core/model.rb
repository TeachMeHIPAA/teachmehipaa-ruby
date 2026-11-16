# frozen_string_literal: true

module TeachMeHipaa
  # The class of OMIT, its only instance; named so signatures can admit it.
  class Omit
    # @return [String] "TeachMeHipaa::OMIT", the constant to pass.
    def inspect = "TeachMeHipaa::OMIT"
  end

  # The default of an optional parameter on a merge-patch method (an
  # update), meaning "leave this field unchanged". Passing +nil+ instead
  # clears the field. Pass OMIT yourself to forward "unchanged":
  #
  #   client.learners.update(id, if_match: learner, name: changes.fetch(:name, TeachMeHipaa::OMIT))
  OMIT = Omit.new.freeze

  # The HTTP response a returned object was read from. +headers+ has
  # lower-case String keys.
  LastResponse = Data.define(:status, :headers) do
    # @api private
    def self.from(response)
      new(status: response.status, headers: response.headers)
    end

    # The id to quote to TeachMeHIPAA support about this response.
    # @return [String, nil]
    def request_id
      headers["x-request-id"]
    end

    # The ETag to send back as +if_match:+ or +if_none_match:+.
    # @return [String, nil]
    def etag
      headers["etag"]
    end
  end

  # Base class for API objects. Subclasses declare their fields, and each
  # field gets a snake_case reader.
  #
  # Models are tolerant (ADR-0006): fields the library doesn't know yet are
  # kept and reachable with #[] and #to_h, and enum fields are plain Strings
  # that may hold values newer than the library.
  class Model
    # @api private
    Field = Data.define(:wire_name, :type) do
      def read(value) = Core::Values.read(type, value)
      def write(value) = Core::Values.write(type, value)
    end
    private_constant :Field

    class << self
      # A subclass starts with its superclass's fields, so a hand-written
      # model (an Operation) keeps the generated ones it extends.
      def fields
        @fields ||= superclass < Model ? superclass.fields.dup : {}
      end

      # The API's JSON for +params+, a Hash keyed by snake_case field names
      # (or the API's own names): known fields under their API names, nested
      # objects converted the same way, unknown keys sent as given.
      # OMIT values are left out.
      def to_wire(params)
        params.each_with_object({}) do |(key, value), wire|
          next if value.is_a?(Omit)

          field = field_for(key)
          wire[field ? field.wire_name : key.to_s] = field ? field.write(value) : Core::Values.write(nil, value)
        end
      end

      private

      # +type+ is nil for JSON values kept as parsed, :time for ISO 8601
      # date-times, a Model subclass or Union module for a nested object,
      # [type] for a list and { String => type } for a map. +reader: false+
      # skips the reader for a name Ruby objects already answer to (such as
      # +method+); #[] still reads it.
      #
      # The macro documents each declared field as a reader in the API
      # reference, under the doc comment written above the declaration.
      #
      # @!macro [attach] field
      #   @!attribute [r] $1
      def field(name, wire_name, type: nil, reader: true)
        fields[name] = Field.new(wire_name:, type:)
        define_method(name) { @values[name] } if reader
      end

      def field_for(key)
        fields[key.to_sym] || fields.each_value.find { |field| field.wire_name == key.to_s }
      end
    end

    # The response this object was read from; nil for nested objects.
    attr_reader :last_response

    def initialize(data, last_response: nil)
      @data = data.freeze
      @values = self.class.fields.to_h { |name, field| [name, field.read(data[field.wire_name])] }
      @last_response = last_response
      freeze
    end

    # False: a model is the object itself. A conditional retrieve returns a
    # NotModified instead when your copy is current.
    def not_modified? = false

    # Reads a field by its snake_case name or by the API's own name. Fields
    # the library doesn't know are returned as raw JSON values.
    def [](key)
      name = key.to_sym
      return @values[name] if @values.key?(name)

      @data[key.to_s]
    end

    # Known fields under snake_case Symbol keys, nested objects as Hashes, and
    # unknown fields under their API names as Symbols.
    def to_h
      known = @values.transform_values { |value| plain(value) }
      unknown = @data.except(*self.class.fields.values.map(&:wire_name))
      known.merge(unknown.transform_keys(&:to_sym))
    end

    # Equal when +other+ is the same class with the same fields.
    def ==(other)
      other.instance_of?(self.class) && other.to_h == to_h
    end
    alias eql? ==

    # Consistent with #==, so models work as Hash keys.
    def hash
      [self.class, to_h].hash
    end

    # @return [String] The class and every field.
    def inspect
      "#<#{self.class.name} #{to_h.map { |key, value| "#{key}: #{value.inspect}" }.join(", ")}>"
    end

    private

    def plain(value)
      case value
      when Model then value.to_h
      when Array then value.map { |item| plain(item) }
      when Hash then value.transform_values { |item| plain(item) }
      else value
      end
    end
  end

  module Core
    # Converts field values between parsed JSON and Ruby, by the field types
    # Model.field takes.
    #
    # @api private
    module Values
      module_function

      def read(type, value)
        return value if value.nil? || type.nil?
        return Time.iso8601(value) if type == :time
        return read_collection(type, value) if type.is_a?(Array) || type.is_a?(Hash)

        type.new(value)
      end

      def read_collection(type, value)
        return value.map { |item| read(type.first, item) } if type.is_a?(Array)

        value.transform_values { |item| read(type[String], item) }
      end

      def write(type, value)
        case value
        when Hash then write_object(type, value)
        when Array then value.map { |item| write(type.is_a?(Array) ? type.first : nil, item) }
        when Time then value.getutc.iso8601
        when Symbol then value.to_s
        else value
        end
      end

      def write_object(type, value)
        return type.to_wire(value) if type.respond_to?(:to_wire)

        inner = type[String] if type.is_a?(Hash)
        value.to_h { |key, item| [key.to_s, write(inner, item)] }
      end
    end
  end
end
