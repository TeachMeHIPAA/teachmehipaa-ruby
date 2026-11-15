# frozen_string_literal: true

module SdkGenerator
  # The Ruby and RBS spelling of IR type references. Included in Ir, which
  # supplies +kind_of+.
  module TypeRefs
    PRIMITIVE_RBS = {
      "string" => "String", "integer" => "Integer", "number" => "Numeric", "boolean" => "bool",
      "dateTime" => "Time", "binary" => "untyped", "json" => "untyped"
    }.freeze
    PRIMITIVE_PARAM_RBS = PRIMITIVE_RBS.merge("dateTime" => "Time | String", "binary" => "upload").freeze

    # The +type:+ argument Model.field takes, or nil when values stay as
    # parsed (strings, numbers, enums, raw JSON).
    def ruby_type(ref)
      case ref.fetch("kind")
      when "primitive" then ":time" if ref.fetch("type") == "dateTime"
      when "ref" then ref.fetch("name") if model?(ref)
      else collection_type(ref)
      end
    end

    def collection_type(ref)
      inner = ruby_type(ref.fetch("items") { ref.fetch("values") })
      return nil if inner.nil?

      ref.fetch("kind") == "array" ? "[#{inner}]" : "{ String => #{inner} }"
    end

    # Model types a field's value is read into, for require_relative.
    def referenced_types(ref)
      case ref.fetch("kind")
      when "ref" then model?(ref) ? [ref.fetch("name")] : []
      when "array" then referenced_types(ref.fetch("items"))
      when "map" then referenced_types(ref.fetch("values"))
      else []
      end
    end

    # The RBS type a reader returns.
    def rbs(ref)
      case ref.fetch("kind")
      when "primitive" then PRIMITIVE_RBS.fetch(ref.fetch("type"))
      when "ref" then kind_of(ref) == "enum" ? "String" : ref.fetch("name")
      when "array" then "Array[#{rbs(ref.fetch("items"))}]"
      when "map" then "Hash[String, #{rbs(ref.fetch("values"))}]"
      end
    end

    # The RBS type a parameter accepts: nested objects are Hashes, enums
    # Strings or Symbols.
    def param_rbs(ref)
      case ref.fetch("kind")
      when "primitive" then PRIMITIVE_PARAM_RBS.fetch(ref.fetch("type"))
      when "ref" then kind_of(ref) == "enum" ? "String | Symbol" : "params"
      when "array" then "Array[#{param_rbs(ref.fetch("items"))}]"
      when "map" then "Hash[String | Symbol, #{param_rbs(ref.fetch("values"))}]"
      end
    end

    private

    def model?(ref)
      %w[object union].include?(kind_of(ref))
    end
  end
end
