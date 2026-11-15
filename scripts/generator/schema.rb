# frozen_string_literal: true

module SdkGenerator
  # Checks the IR against its vendored JSON Schema, so a newer IR shape fails
  # with the schema's own complaint instead of as broken generated code.
  # Covers the keywords sdk-ir.schema.json uses; +format+ is only tolerated.
  class Schema
    TYPES = {
      "object" => ->(value) { value.is_a?(Hash) },
      "array" => ->(value) { value.is_a?(Array) },
      "string" => ->(value) { value.is_a?(String) },
      "integer" => ->(value) { value.is_a?(Integer) },
      "number" => ->(value) { value.is_a?(Numeric) },
      "boolean" => ->(value) { [true, false].include?(value) },
      "null" => lambda(&:nil?),
    }.freeze

    def initialize(schema)
      @root = schema
    end

    # Up to +limit+ problems as "/json/pointer message" Strings.
    def errors(value, limit: 10)
      check(@root, value, "").first(limit)
    end

    private

    def check(schema, value, at)
      return check(resolve(schema["$ref"]), value, at) if schema.key?("$ref")

      [*type_errors(schema, value, at), *value_errors(schema, value, at), *combinator_errors(schema, value, at),
       *object_errors(schema, value, at), *array_errors(schema, value, at)]
    end

    def resolve(ref)
      ref.delete_prefix("#/").split("/").reduce(@root) { |node, key| node.fetch(key) }
    end

    def type_errors(schema, value, at)
      types = Array(schema["type"])
      return [] if types.empty? || types.any? { |type| TYPES.fetch(type).call(value) }

      ["#{at} must be #{types.join(" or ")}"]
    end

    def value_errors(schema, value, at)
      [
        ("#{at} must equal #{schema["const"].inspect}" if schema.key?("const") && value != schema["const"]),
        ("#{at} must be one of #{schema["enum"].inspect}" if schema.key?("enum") && !schema["enum"].include?(value)),
        *(value.is_a?(String) ? string_errors(schema, value, at) : []),
        *(value.is_a?(Numeric) ? number_errors(schema, value, at) : []),
      ].compact
    end

    def string_errors(schema, value, at)
      [
        ("#{at} is shorter than #{schema["minLength"]}" if schema["minLength"] && value.length < schema["minLength"]),
        ("#{at} must match #{schema["pattern"]}" if schema["pattern"] && !Regexp.new(schema["pattern"]).match?(value)),
      ].compact
    end

    def number_errors(schema, value, at)
      [
        ("#{at} must be <= #{schema["maximum"]}" if schema["maximum"] && value > schema["maximum"]),
        ("#{at} must be >= #{schema["minimum"]}" if schema["minimum"] && value < schema["minimum"]),
        ("#{at} must be > #{schema["exclusiveMinimum"]}" if schema["exclusiveMinimum"] &&
          value <= schema["exclusiveMinimum"]),
      ].compact
    end

    def combinator_errors(schema, value, at)
      errors = []
      errors << "#{at} matches none of anyOf" if schema["anyOf"]&.none? { |option| check(option, value, at).empty? }
      if schema["oneOf"] && schema["oneOf"].count { |option| check(option, value, at).empty? } != 1
        errors << "#{at} must match exactly one of oneOf"
      end
      errors
    end

    def object_errors(schema, value, at)
      return [] unless value.is_a?(Hash)

      properties = schema.fetch("properties", {})
      missing = (schema["required"] || []).reject { |name| value.key?(name) }.map { |name| "#{at} lacks #{name}" }
      missing + value.flat_map { |name, item| property_errors(schema, properties, name, item, "#{at}/#{name}") }
    end

    def property_errors(schema, properties, name, item, at)
      names = schema["propertyNames"] ? check(schema["propertyNames"], name, at) : []
      return names + check(properties[name], item, at) if properties.key?(name)

      extra = schema.fetch("additionalProperties", true)
      return names + ["#{at} is not allowed"] if extra == false
      return names + check(extra, item, at) if extra.is_a?(Hash)

      names
    end

    def array_errors(schema, value, at)
      return [] unless value.is_a?(Array)

      minimum = schema["minItems"]
      short = minimum && value.length < minimum ? ["#{at} has fewer than #{minimum} items"] : []
      return short unless schema["items"]

      short + value.each_with_index.flat_map { |item, i| check(schema["items"], item, "#{at}/#{i}") }
    end
  end
end
