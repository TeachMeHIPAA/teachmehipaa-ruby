# frozen_string_literal: true

module TeachMeHipaa
  # The HTTP response a returned object was read from. +headers+ has
  # lower-case String keys.
  LastResponse = Data.define(:status, :headers) do
    def self.from(response)
      new(status: response.status, headers: response.headers)
    end

    def request_id
      headers["x-request-id"]
    end

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
    Field = Data.define(:wire_name, :type) do
      def read(value)
        return nil if value.nil?

        case type
        when nil then value
        when :time then Time.iso8601(value)
        when Array then value.map { |item| type.first.new(item) }
        else type.new(value)
        end
      end
    end
    private_constant :Field

    class << self
      def fields
        @fields ||= {}
      end

      private

      # +type+ is nil for JSON scalars, :time for ISO 8601 date-times, a
      # Model subclass for a nested object, or [ModelSubclass] for a list.
      def field(name, wire_name, type: nil)
        fields[name] = Field.new(wire_name:, type:)
        define_method(name) { @values[name] }
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

    def ==(other)
      other.instance_of?(self.class) && other.to_h == to_h
    end
    alias eql? ==

    def hash
      [self.class, to_h].hash
    end

    def inspect
      "#<#{self.class.name} #{to_h.map { |key, value| "#{key}: #{value.inspect}" }.join(", ")}>"
    end

    private

    def plain(value)
      case value
      when Model then value.to_h
      when Array then value.map { |item| plain(item) }
      else value
      end
    end
  end
end
