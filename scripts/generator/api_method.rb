# frozen_string_literal: true

module SdkGenerator
  # One IR method's parameters: path params positional, query and body
  # fields as keywords, and If-Match as +if_match:+ where the IR asks for it.
  class ApiMethod
    MERGE_PATCH = "application/merge-patch+json"
    RESERVED_PARAMS = %w[request_options if_match].freeze
    PATCH_NOTE = "Parameters you leave out are unchanged; pass nil to clear one."
    STRING = { "kind" => "primitive", "type" => "string" }.freeze

    # +body+ is true for a request-body field.
    Param = Data.define(:ruby, :wire, :required, :nullable, :type, :body)

    attr_reader :data, :where, :body

    def initialize(context, resource_path, data)
      @ir = context
      @data = data
      @where = [*resource_path, data.fetch("name")].join(".")
      @body = data["requestBody"]
      Checks.new(self).run
    end

    def ruby_name
      Naming.snake(data.fetch("name"))
    end

    def doc
      [data["summary"], data["description"], *constraint_notes, (PATCH_NOTE if merge_patch?)]
    end

    def merge_patch?
      @body&.fetch("contentType") == MERGE_PATCH
    end

    def path_params
      data.fetch("pathParams").map { |field| param(field, true) }
    end

    def query_params
      data.fetch("queryParams").map { |field| param(field, field.fetch("required")) }
    end

    def if_match
      requirement = data.fetch("ifMatch")
      return nil if requirement == "none"

      Param.new(ruby: "if_match", wire: "If-Match", required: requirement == "required", nullable: false,
                type: STRING, body: false)
    end

    def body_type
      return nil if @body.nil?

      ref = @body.fetch("type")
      raise ArgumentError, "#{where}: the body must reference an object type" unless @ir.kind_of(ref) == "object"

      @ir.type(ref.fetch("name"))
    end

    # The body's fields, less those a const constraint fixes outright.
    def body_params
      return [] if body_type.nil?

      fixed = constraints("const").map { |constraint| constraint.fetch("path") }.select { |path| path.length == 1 }
      body_type.fetch("fields").reject { |field| fixed.include?([field.fetch("name")]) }
               .map { |field| param(field, @body.fetch("required") && field.fetch("required"), body: true) }
    end

    def keywords
      [*query_params, *body_params]
    end

    def required_keywords
      [if_match, *body_params, *query_params].compact.select(&:required)
    end

    def optional_keywords
      [*body_params, if_match, *query_params].compact.reject(&:required)
    end

    def constraints(kind)
      (@body ? @body.fetch("constraints") : []).select { |constraint| constraint.fetch("kind") == kind }
    end

    def ruby_parameters
      [*path_params.map(&:ruby), *required_keywords.map { |param| "#{param.ruby}:" },
       *optional_keywords.map { |param| "#{param.ruby}: #{merge_patch? && param.body ? "OMIT" : "nil"}" },
       "request_options: {}"]
    end

    def rbs_parameters
      [*path_params.map { |param| "String #{param.ruby}" },
       *required_keywords.map { |param| "#{param.ruby}: #{param_rbs(param)}" },
       *optional_keywords.map { |param| "?#{param.ruby}: #{param_rbs(param, optional: true)}" },
       "?request_options: request_options"]
    end

    def rbs_return
      response = data.fetch("response")
      case response.fetch("kind")
      when "page" then "Page[#{@ir.rbs(data.dig("pagination", "itemType"))}]"
      when "empty" then "EmptyResponse"
      when "binary" then "BinaryResponse"
      else @ir.rbs(response.fetch("type"))
      end
    end

    private

    def param(field, required, body: false)
      Param.new(ruby: Naming.snake(field.fetch("name")), wire: field.fetch("name"), required:,
                nullable: field.fetch("nullable", false), type: field.fetch("type"), body:)
    end

    def param_rbs(param, optional: false)
      rbs = param.wire == "If-Match" ? "String" : @ir.param_rbs(param.type)
      param.nullable || (optional && !(merge_patch? && param.body)) ? Ir.optional(rbs) : rbs
    end

    def constraint_notes
      variants = constraints("variant").map do |constraint|
        "+#{snake_path(constraint)}+ takes the form with +#{Naming.snake(constraint.fetch("requiredProperty"))}+."
      end
      fixed = constraints("const").map do |constraint|
        "Sets +#{snake_path(constraint)}+ to #{Text.literal(constraint.fetch("value"))} itself."
      end
      variants + fixed
    end

    def snake_path(constraint)
      constraint.fetch("path").map { |key| Naming.snake(key) }.join(".")
    end

    # Refuses IR shapes the generated Ruby can't express, naming the method.
    class Checks
      def initialize(method)
        @method = method
        @data = method.data
      end

      def run
        fail!("header parameters aren't supported") unless @data.fetch("headerParams").empty?
        check_path
        check_names
        constraint = @method.constraints("const").find { |const| const.fetch("path").length > 2 }
        fail!("const constraint #{constraint.fetch("path").join(".")} is nested too deep") if constraint
      end

      private

      def fail!(message)
        raise ArgumentError, "#{@method.where}: #{message}"
      end

      def check_path
        template = @data.dig("path", "template")
        fail!("orgScoped disagrees with #{template}") if @data.fetch("orgScoped") != template.include?("{orgId}")
        placeholders = template.scan(/\{(\w+)\}/).flatten - ["orgId"]
        fail!("path params don't match #{template}") unless placeholders == @method.path_params.map(&:wire)
        non_string = @method.path_params.find { |param| param.type != STRING || Naming.keyword?(param.ruby) }
        fail!("path param #{non_string.wire} can't be a positional String") if non_string
      end

      def check_names
        names = [*@method.path_params, *@method.keywords].map(&:ruby)
        clash = names.find { |name| names.count(name) > 1 || RESERVED_PARAMS.include?(name) }
        fail!("parameter #{clash} clashes with another name") if clash
      end
    end
  end
end
