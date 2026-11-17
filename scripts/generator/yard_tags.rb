# frozen_string_literal: true

module SdkGenerator
  # The YARD tags under a resource method's doc comment in the Ruby source,
  # which editors and documentation tools render. The types match the
  # method's RBS signature.
  class YardTags
    REQUEST_OPTIONS_DOC = "Options for this call only: +idempotency_key+, +max_retries+, +timeout+, " \
                          "+request_id+ and +headers+."
    CHUNK_DOC = "The next chunk of the file's bytes."
    ETAG_DOC = "The ETag of the copy you hold: a String, or the object you read."

    def initialize(method)
      @method = method
      @ir = method.ir
    end

    def comment(column)
      tags = [*self.class.parameters(@method).map { |param| param_tag(param) },
              "@param request_options [Hash] #{REQUEST_OPTIONS_DOC}",
              *(["@yieldparam chunk [String] #{CHUNK_DOC}"] if @method.binary?),
              "@return [#{self.class.returns(@method)}]"]
      tags.map { |tag| lines(tag, column) }.join
    end

    # With +if_none_match:+ a method may also return NotModified, and a
    # download given a block returns a StreamedResponse.
    def self.returns(method)
      data = method.data
      returned = case data.dig("response", "kind")
                 when "page" then "Page<#{method.ir.yard(data.dig("pagination", "itemType"))}>"
                 when "operation" then method.operation_model
                 when "empty" then "EmptyResponse"
                 when "binary" then "BinaryResponse, StreamedResponse"
                 else method.ir.yard(data.dig("response", "type"))
                 end
      method.if_none_match ? "#{returned}, NotModified" : returned
    end

    # Every parameter in signature order: path params, then keywords.
    def self.parameters(method)
      [*method.path_params, *method.required_keywords, *method.optional_keywords]
    end

    # The conditional headers' parameters have no IR description.
    def self.description(param)
      return ETAG_DOC if param.type.nil?

      param.description.to_s.split.join(" ")
    end

    def self.type(method, param)
      return "String" if method.path_params.include?(param)
      return "String, Model" if param.type.nil?

      yard = method.ir.param_yard(param.type)
      optional = param.nullable || (!param.required && !(method.merge_patch? && param.body))
      optional ? Ir.optional_yard(yard) : yard
    end

    private

    def param_tag(param)
      "@param #{param.ruby} [#{self.class.type(@method, param)}] #{self.class.description(param)}".rstrip
    end

    # A tag's continuation lines are indented, as YARD requires.
    def lines(tag, column)
      first, *rest = Text.wrap_words(tag, Text::COMMENT_WIDTH - column - 4)
      ["# #{first}\n", *rest.map { |line| "#   #{line}\n" }].join
    end
  end
end
