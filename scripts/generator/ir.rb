# frozen_string_literal: true

module SdkGenerator
  # The parsed IR, with lookups and the Ruby and RBS spelling of its type
  # references.
  class Ir
    include TypeRefs

    # Readers Ruby objects already answer to; a field with one of these
    # names gets no reader (Model.field's +reader: false+). A fixed list, so
    # output doesn't depend on what the generating process has loaded.
    RESERVED_READERS = %w[
      class clone display dup enum_for equal? eql? extend freeze frozen? hash inspect instance_of?
      instance_variable_get instance_variables is_a? itself kind_of? last_response method methods nil?
      object_id public_send respond_to? send singleton_class tap then to_enum to_h to_s yield_self
    ].freeze

    attr_reader :data

    def initialize(data)
      @data = data
      @types = data.fetch("types").to_h { |type| [type.fetch("name"), type] }
    end

    def types
      @types.values.sort_by { |type| type.fetch("name") }
    end

    def type(name)
      @types.fetch(name) { raise ArgumentError, "IR references unknown type #{name}" }
    end

    def resources
      data.fetch("resources")
    end

    def kind_of(ref)
      ref.fetch("kind") == "ref" ? type(ref.fetch("name")).fetch("kind") : nil
    end

    # The union modules each object type is a variant of, with the
    # discriminator value(s) that pick it.
    def unions_of(name)
      union_members.fetch(name, [])
    end

    # The Event union's fallback is the IR's own generic Event type, so
    # webhooks and the Event log read unknown Event types the same way.
    def union_fallback(union)
      discriminator = union.fetch("discriminator")
      return discriminator["fallback"] if discriminator["fallback"]
      return data.dig("events", "unknownEvent") if union.fetch("name") == data.dig("events", "envelope")

      "#{union.fetch("name")}::Unknown"
    end

    def self.optional(rbs)
      return rbs if rbs == "untyped"

      rbs.include?(" ") ? "(#{rbs})?" : "#{rbs}?"
    end

    def self.optional_yard(yard)
      yard == "Object" ? yard : "#{yard}, nil"
    end

    def self.reader_name(field)
      Naming.snake(field.fetch("name"))
    end

    def self.reader?(field)
      !RESERVED_READERS.include?(reader_name(field))
    end

    # An object type's fields, plus the discriminator of a union it is a
    # variant of when the IR doesn't declare it.
    def object_fields(type)
      declared = type.fetch("fields")
      names = declared.map { |field| field.fetch("name") }
      added = unions_of(type.fetch("name")).filter_map do |union|
        property = type(union).dig("discriminator", "property")
        next if property.nil? || names.include?(property)

        { "name" => property, "description" => nil, "required" => true, "nullable" => false,
          "type" => { "kind" => "primitive", "type" => "string" } }
      end
      declared + added.uniq
    end

    # The type a Learner write (create, upsert) returns, which gets created?.
    def write_result?(name)
      @write_results ||= resources.flat_map { |resource| resource.fetch("methods") }
                                  .map { |method| method.fetch("response") }
                                  .select { |response| response.fetch("kind") == "writeResult" }
                                  .map { |response| response.dig("type", "name") }
      @write_results.include?(name)
    end

    # Constant name => value for an enum type.
    def enum_constants(type)
      constants = type.fetch("values").to_h { |value| [Naming.constant(value), value] }
      return constants if constants.size == type.fetch("values").size

      raise ArgumentError, "#{type.fetch("name")}: enum values collide as constants"
    end

    # A field's doc comment paragraphs.
    def field_doc(field)
      ref = field.fetch("type")
      ref = ref.fetch("items") while ref.fetch("kind") == "array"
      enum = kind_of(ref) == "enum" ? "See #{ref.fetch("name")} for known values; the API may send newer ones." : nil
      [field["description"], enum]
    end

    private

    def union_members
      @union_members ||= types.select { |type| type.fetch("kind") == "union" }.each_with_object({}) do |union, all|
        members = union.fetch("discriminator").fetch("mapping").values + [union_fallback(union)]
        members.uniq.each { |member| (all[member] ||= []) << union.fetch("name") unless member.include?("::") }
      end
    end
  end
end
