# frozen_string_literal: true

module SdkGenerator
  # A resource method's RBS signature, with an overload per return type.
  class RbsSignature
    COLUMN = 6

    def initialize(method)
      @method = method
      @ir = method.ir
      @data = method.data
    end

    def source
      lines = overloads.each_with_index.map do |(parameters, returns), index|
        head = index.zero? ? "def #{@method.ruby_name}: (" : "#{" " * (@method.ruby_name.length + 4)}| ("
        Text.pack(head, parameters, returns.start_with?("{") ? ") #{returns}" : ") -> #{returns}", COLUMN)
      end
      Text.comment(@method.doc, COLUMN) + lines.join
    end

    private

    # [parameters, return type] pairs: a method that takes If-None-Match
    # returns NotModified only when given it, and a download given a block
    # streams to it.
    def overloads
      return [[parameters, returns], [parameters, "{ (String chunk) -> void } -> StreamedResponse"]] if @method.binary?
      return [[parameters, returns]] if @method.if_none_match.nil?

      optional = "?if_none_match: etag?"
      [[parameters - [optional], returns],
       [parameters.map { |param| param == optional ? "if_none_match: etag?" : param }, "(#{returns} | NotModified)"]]
    end

    def parameters
      [*@method.path_params.map { |param| "String #{param.ruby}" },
       *@method.required_keywords.map { |param| "#{param.ruby}: #{type(param)}" },
       *@method.optional_keywords.map { |param| "?#{param.ruby}: #{type(param, optional: true)}" },
       "?request_options: request_options"]
    end

    def returns
      response = @data.fetch("response")
      case response.fetch("kind")
      when "page" then "Page[#{@ir.rbs(@data.dig("pagination", "itemType"))}]"
      when "operation" then @method.operation_model
      when "empty" then "EmptyResponse"
      when "binary" then "BinaryResponse"
      else @ir.rbs(response.fetch("type"))
      end
    end

    # A conditional header's ETag has no IR type. An optional merge-patch
    # field defaults to OMIT, and takes nil only when nullable.
    def type(param, optional: false)
      rbs = param.type.nil? ? "etag" : @ir.param_rbs(param.type)
      return "#{param.nullable ? Ir.optional(rbs) : rbs} | Omit" if optional && omittable?(param)

      param.nullable || optional ? Ir.optional(rbs) : rbs
    end

    def omittable?(param)
      @method.merge_patch? && param.body
    end
  end
end
