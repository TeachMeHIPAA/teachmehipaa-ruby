# frozen_string_literal: true

module SdkGenerator
  # The Core::Requestor#request call a resource method makes.
  class RequestCall
    JSON_TYPE = "application/json"
    COLUMN = 10

    def initialize(method)
      @method = method
      @data = method.data
    end

    def source
      arguments = [
        "method: #{Text.literal(@data.fetch("httpMethod"))}\n",
        "path: #{Text.literal(path)}\n",
        *hash_argument("path_params", @method.path_params),
        *hash_argument("query", @method.query_params),
        *conditional_arguments,
        *body_arguments,
        *("retry_safe: true\n" if @data.fetch("retrySafe")),
        *("idempotency_key: :required\n" if @data.fetch("idempotencyKey") == "required"),
        *("authenticated: false\n" if @method.public?),
        *response_arguments,
        "request_options:\n",
      ]
      listed = arguments.map { |argument| argument.sub(/\n\z/, ",\n") }.join + ("&\n" if @method.binary?).to_s
      "request(\n#{Text.indent(listed, 2)})\n"
    end

    private

    def path
      verb = @data.dig("path", "customVerb")
      template = @data.dig("path", "template")
      verb ? "#{template}:#{verb}" : template
    end

    def hash_argument(name, params)
      return [] if params.empty?

      items = params.map do |param|
        value = Naming.read_parameter(param.ruby)
        param.wire == value ? "#{value}:" : "#{param.wire}: #{value}"
      end
      [Text.pack("#{name}: { ", items, " }", COLUMN)]
    end

    def conditional_arguments
      [@method.if_match, @method.if_none_match].compact.map { |param| "#{param.ruby}:\n" }
    end

    def body_arguments
      body = @method.body
      return [] if body.nil?

      [body_argument,
       *("content_type: #{Text.literal(body.fetch("contentType"))}\n" unless body.fetch("contentType") == JSON_TYPE),
       *binary_parts_argument(body.fetch("binaryParts"))]
    end

    # Merge-patch bodies keep explicit nils (to_wire drops OMIT); other
    # bodies drop the nil defaults of parameters left out.
    def body_argument
      params = @method.body_params
      compact = @method.merge_patch? || params.all?(&:required) ? "" : ".compact"
      head, tail = @method.constraints("const").reduce(["#{@method.body_type.fetch("name")}.to_wire({ ",
                                                        " }#{compact})"]) do |(before, after), constraint|
        ["fixed(#{before}", "#{after}, #{path_literal(constraint.fetch("path"))}, " \
                            "#{Text.literal(constraint.fetch("value"))})"]
      end
      Text.pack("body: #{head}", params.map { |param| shorthand(param) }, tail, COLUMN)
    end

    def shorthand(param)
      value = Naming.read_parameter(param.ruby)
      value == param.ruby ? "#{value}:" : "#{param.ruby}: #{value}"
    end

    def path_literal(path)
      path.length > 1 ? "%w[#{path.join(" ")}]" : Text.literal(path)
    end

    def binary_parts_argument(parts)
      return [] if parts.empty?

      pairs = parts.map { |part| "#{Text.literal(part.fetch("name"))} => #{Text.literal(part.fetch("contentType"))}" }
      ["binary_parts: { #{pairs.join(", ")} }\n"]
    end

    def response_arguments
      response = @data.fetch("response")
      case response.fetch("kind")
      when "page" then ["response: :page\n", "model: #{@data.dig("pagination", "itemType", "name")}\n", pagination]
      when "writeResult" then ["response: :write_result\n", "model: #{response.dig("type", "name")}\n"]
      when "operation" then ["response: :operation\n", "model: #{@method.operation_model}\n"]
      when "empty" then ["response: :empty\n"]
      when "binary" then ["response: :binary\n", "accept: #{Text.literal(response.fetch("contentType"))}\n"]
      else ["model: #{response.dig("type", "name")}\n"]
      end
    end

    def pagination
      style, cursor_param = @data.fetch("pagination").values_at("style", "cursorParam")
      "pagination: { style: :#{style}, cursor_param: #{Text.literal(cursor_param)} }\n"
    end
  end
end
