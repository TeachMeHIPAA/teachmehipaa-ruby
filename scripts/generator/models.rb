# frozen_string_literal: true

module SdkGenerator
  # One Ruby file and one RBS file per IR type, plus the models.rb index.
  class Models
    LIB = "lib/teachmehipaa/models"
    SIG = "sig/teachmehipaa/models"
    # Object types with hand-written methods, by IR name. Their generated
    # class is <Name>Base; extensions/<file>.rb subclasses it under the plain
    # name, which every reference to the type means, and
    # sig/teachmehipaa/extensions/<file>.rbs signs it.
    EXTENDED_MODELS = %w[Operation].freeze

    def self.generated_class(name)
      EXTENDED_MODELS.include?(name) ? "#{name}Base" : name
    end

    def initialize(ir)
      @ir = ir
    end

    def files
      ruby = ModelSource.new(@ir)
      rbs = ModelSignature.new(@ir)
      files = @ir.types.each_with_object({}) do |type, all|
        file = Naming.snake(type.fetch("name"))
        raise ArgumentError, "two IR types map to #{file}.rb" if all.key?("#{LIB}/#{file}.rb")

        all["#{LIB}/#{file}.rb"] = ruby.source(type)
        all["#{SIG}/#{file}.rbs"] = rbs.source(type)
      end
      files.merge("lib/teachmehipaa/models.rb" => Text::RUBY_HEADER + index)
    end

    private

    # The extensions load after every generated class they may build on.
    def index
      check_extended
      models = @ir.types.map { |type| "models/#{Naming.snake(type.fetch("name"))}" }
      Text.require_lines(models + EXTENDED_MODELS.map { |name| "extensions/#{Naming.snake(name)}" })
    end

    def check_extended
      missing = EXTENDED_MODELS.reject { |name| @ir.types.any? { |type| type.fetch("name") == name } }
      raise ArgumentError, "extended model(s) not in the IR: #{missing.join(", ")}" if missing.any?
    end
  end

  # Doc comments shared by a model's Ruby and RBS.
  module ModelDocs
    MERGE_PATCH_NOTE = "Sent as a JSON merge patch: leave a field out to keep it; nil clears a nullable field."
    ENUM_NOTE = "Known values; the API may add more at any time, so handle values you don't recognize."

    private

    def type_doc(type)
      name = type.fetch("name")
      return extended_doc(name) if Models::EXTENDED_MODELS.include?(name)

      fallback = type.fetch("kind") == "object" ? "#{Text.article(name)} #{name} object." : nil
      Text.comment([type["description"] || fallback, (MERGE_PATCH_NOTE if type["mergePatch"]), *kind_note(type)], 2)
    end

    def extended_doc(name)
      Text.comment(["The generated fields of #{name}. The library returns the hand-written subclass #{name} in " \
                    "lib/teachmehipaa/extensions/#{Naming.snake(name)}.rb."], 2)
    end

    def kind_note(type)
      case type.fetch("kind")
      when "enum" then ENUM_NOTE
      when "union" then union_note(type.fetch("discriminator"))
      end
    end

    def union_note(discriminator)
      return "The variant is picked by which field is present." unless discriminator.fetch("kind") == "property"

      "Tell the variants apart by +#{Naming.snake(discriminator.fetch("property"))}+ or by class. " \
        "New variants may be added; handle ones you don't recognize."
    end

    def unknown_class?(type)
      @ir.union_fallback(type) == "#{type.fetch("name")}::Unknown"
    end

    def unknown_doc(name)
      Text.comment(["#{Text.article(name)} #{name} this library doesn't know yet. Its fields are all kept; " \
                    "read them with #[] or #to_h."], 4)
    end

    def includes(name)
      lines = @ir.unions_of(name).map { |union| "include #{union}\n" }.join
      lines.empty? ? "" : "#{lines}\n"
    end

    def unknown_class(name)
      Text.block("class Unknown < Model", "include #{name}\n")
    end

    def created_doc
      Text.comment(["True when this call created the Learner (201), false when it already existed (200)."], 4)
    end
  end

  # A model's Ruby source.
  class ModelSource
    include ModelDocs

    def initialize(ir)
      @ir = ir
    end

    def source(type)
      body = case type.fetch("kind")
             when "object" then object(type)
             when "enum" then enum(type)
             when "union" then union(type)
             end
      requires = Text.require_lines(dependencies(type).map { |name| Naming.snake(name) })
      Text::RUBY_HEADER + (requires.empty? ? "" : "#{requires}\n") + Text.block("module TeachMeHipaa", body)
    end

    private

    # Variant classes require their union module (to include it); union
    # modules name their variants lazily, so the require graph has no cycle.
    def dependencies(type)
      return [] unless type.fetch("kind") == "object"

      referenced = @ir.object_fields(type).flat_map { |field| @ir.referenced_types(field.fetch("type")) }
      (referenced + @ir.unions_of(type.fetch("name"))).uniq.sort - [type.fetch("name")]
    end

    def object(type)
      name = type.fetch("name")
      fields = @ir.object_fields(type).map { |field| field(field) }.join
      created = @ir.write_result?(name) ? "\n#{created_doc}def created? = created\n" : ""
      type_doc(type) + Text.block("class #{Models.generated_class(name)} < Model", includes(name) + fields + created)
    end

    def field(field)
      args = [":#{Ir.reader_name(field)}", Text.literal(field.fetch("name"))]
      @ir.ruby_type(field.fetch("type"))&.then { |type| args << "type: #{type}" }
      args << "reader: false" unless Ir.reader?(field)
      "#{Text.comment(@ir.field_doc(field) + yard_tags(field), 4)}field #{args.join(", ")}\n"
    end

    # Model.field's YARD macro documents each field as a reader; a field
    # without one is hidden from the API reference instead.
    def yard_tags(field)
      unless Ir.reader?(field)
        return ["No reader: +#{Ir.reader_name(field)}+ is already a Ruby method. Read it with #[].",
                "@!visibility private"]
      end

      type = @ir.yard(field.fetch("type"))
      ["@return [#{field.fetch("nullable") || !field.fetch("required") ? Ir.optional_yard(type) : type}]"]
    end

    def enum(type)
      constants = @ir.enum_constants(type).map { |constant, value| "#{constant} = #{Text.literal(value)}\n" }
      type_doc(type) + Text.block("module #{type.fetch("name")}", constants.join)
    end

    def union(type)
      name = type.fetch("name")
      unknown = unknown_class?(type) ? "#{unknown_doc(name)}#{unknown_class(name)}\n" : ""
      type_doc(type) + Text.block("module #{name}", "extend Union\n\n#{unknown}#{variants(type)}")
    end

    def variants(type)
      discriminator = type.fetch("discriminator")
      mapping = discriminator.fetch("mapping").sort.map do |key, member|
        "#{Text.literal(key)} => #{Text.literal(member)},\n"
      end
      options = [*("property: #{Text.literal(discriminator["property"])}" if discriminator["property"]),
                 "fallback: #{Text.literal(@ir.union_fallback(type))}"].map { |option| "#{option},\n" }
      "variants(\n#{Text.indent("{\n#{Text.indent(mapping.join, 2)}},\n#{options.join}", 2)})\n"
    end
  end

  # A model's RBS signature.
  class ModelSignature
    include ModelDocs

    def initialize(ir)
      @ir = ir
    end

    def source(type)
      body = case type.fetch("kind")
             when "object" then object(type)
             when "enum" then enum(type)
             when "union" then union(type)
             end
      "#{Text::BANNER}\n#{Text.block("module TeachMeHipaa", body)}"
    end

    private

    def object(type)
      name = type.fetch("name")
      readers = @ir.object_fields(type).select { |field| Ir.reader?(field) }.map { |field| reader(field) }
      readers << "#{created_doc}def created?: () -> bool\n" if @ir.write_result?(name)
      type_doc(type) + Text.block("class #{Models.generated_class(name)} < Model", includes(name) + readers.join)
    end

    def reader(field)
      type = @ir.rbs(field.fetch("type"))
      type = Ir.optional(type) if field.fetch("nullable") || !field.fetch("required")
      "#{Text.comment(@ir.field_doc(field), 4)}def #{Ir.reader_name(field)}: () -> #{type}\n"
    end

    def enum(type)
      constants = @ir.enum_constants(type).keys.map { |constant| "#{constant}: String\n" }
      type_doc(type) + Text.block("module #{type.fetch("name")}", constants.join)
    end

    def union(type)
      name = type.fetch("name")
      unknown = unknown_class?(type) ? "\n#{unknown_class(name)}" : ""
      type_doc(type) + Text.block("module #{name}", "extend Union\n#{unknown}")
    end
  end
end
