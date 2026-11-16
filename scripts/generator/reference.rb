# frozen_string_literal: true

module SdkGenerator
  # docs/reference/resources.md: every resource method with its Ruby call,
  # HTTP request, Scopes, retry and conditional behaviour, parameters and
  # return type.
  class Reference
    PATH = "docs/reference/resources.md"
    BANNER = "<!-- Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`. -->"
    API_REFERENCE = "https://teachmehipaa.github.io/teachmehipaa-ruby/"

    def initialize(ir)
      @ir = ir
    end

    def files
      { PATH => [BANNER, intro, contents, *nodes.map { |node| resource(*node) }].join("\n\n").concat("\n") }
    end

    def self.accessor(path)
      "client.#{path.map { |segment| Naming.snake(segment) }.join(".")}"
    end

    private

    # Resources by their client accessor, children after their parent.
    def nodes
      @nodes ||= @ir.resources.sort_by { |resource| resource.fetch("path") }.map do |resource|
        [resource.fetch("path"), resource.fetch("methods").sort_by { |method| method.fetch("name") }]
      end
    end

    def title(path)
      words = Naming.snake(path.last).tr("_", " ")
      words[0].upcase + words[1..]
    end

    def intro
      live, sandbox = %w[live sandbox].map { |name| server_url(name) }
      <<~MARKDOWN.chomp
        # Resource reference

        Each method the client offers, one section apiece, generated from the
        Developer API document release `#{@ir.data.dig("source", "release")}`. The extras the gem
        layers on top (`events.tail`, `Operation#wait`, `Webhook`) live in the
        [guides](../README.md), and every class and field is in the
        [API reference](#{API_REFERENCE}).

        How to read a section:

        - The Ruby line shows the call with its defaults. Ids in the URL are
          positional; the rest are keywords.
        - Every method also takes `request_options:`, a Hash with
          `idempotency_key`, `max_retries`, `timeout`, `request_id` and `headers`
          ([Setting up a client](../guides/client.md#options-for-one-call)).
        - HTTP paths are relative to `#{live}` (Live) or
          `#{sandbox}` (Sandbox). The client fills in
          `{orgId}` itself, so no method asks for an Organization id.
        - Types use YARD notation. Enum fields are Strings and can hold values
          newer than this gem.
      MARKDOWN
    end

    def server_url(environment)
      @ir.data.fetch("servers").find { |server| server.fetch("environment") == environment }.fetch("url")
    end

    def contents
      lines = nodes.map do |path, methods|
        names = methods.map { |method| "`#{Naming.snake(method.fetch("name"))}`" }.join(", ")
        "- [#{title(path)}](##{title(path).downcase.tr(" ", "-")}): #{names}"
      end
      "## Contents\n\n#{lines.join("\n")}"
    end

    def resource(path, methods)
      sections = methods.map { |data| ReferenceMethod.new(ApiMethod.new(@ir, path, data), path).source }
      ["## #{title(path)}\n\n`#{Reference.accessor(path)}`", *sections].join("\n\n")
    end
  end

  # One method's section of the resource reference.
  class ReferenceMethod
    CODE_WIDTH = 80
    NOT_MODIFIED = "Pass `if_none_match:` and a current copy comes back as `NotModified`"
    MERGE_PATCH = "A JSON merge patch. Leave a keyword out to keep the field, pass `nil` to clear it"

    def initialize(method, path)
      @method = method
      @call = "#{Reference.accessor(path)}.#{method.ruby_name}"
    end

    def source
      [
        "### `#{@call}`",
        "**#{@method.data.fetch("summary")}.** #{@method.data["description"]}".strip,
        "```ruby\n#{signatures.join("\n")}\n```",
        facts,
        parameter_table,
      ].join("\n\n")
    end

    private

    def signatures
      arguments = @method.ruby_parameters - ["&"]
      whole = @method.binary? ? "BinaryResponse" : YardTags.returns(@method).split(", ").first
      lines = [pack(arguments, ") # => #{whole}")]
      lines << pack(arguments, ") { |chunk| ... } # => StreamedResponse") if @method.binary?
      lines
    end

    # Text.pack wraps at Text::LINE_WIDTH from a starting column; starting
    # this far in wraps at CODE_WIDTH instead.
    def pack(arguments, tail)
      Text.pack("#{@call}(", arguments, tail, Text::LINE_WIDTH - CODE_WIDTH).chomp
    end

    def facts
      facts = [
        ["HTTP", "`#{@method.data.fetch("httpMethod")} #{http_path}`"],
        ["Scopes", scopes],
        ["Returns", "`#{YardTags.returns(@method)}`"],
        ["Retried", retries],
        *conditional_facts,
      ]
      facts.map { |name, text| "- **#{name}:** #{text}." }.join("\n")
    end

    def http_path
      verb = @method.data.dig("path", "customVerb")
      template = @method.data.dig("path", "template")
      verb ? "#{template}:#{verb}" : template
    end

    def scopes
      return "None. The client sends no Access token" if @method.public?
      return "Any Access token will do" if Scopes.any_token?(@method)

      Scopes.phrase(@method) { |scope| "`#{scope}`" }
    end

    def retries
      return "No" unless @method.data.fetch("retrySafe")
      return "Yes, it is safe to replay" unless @method.data.fetch("idempotencyKey") == "required"

      "Yes. Each call sends a fresh `Idempotency-Key` and its retries reuse it"
    end

    def conditional_facts
      {
        "If-Match" => (if_match if @method.if_match),
        "If-None-Match" => (NOT_MODIFIED if @method.if_none_match),
        "Body" => (MERGE_PATCH if @method.merge_patch?),
      }.compact.to_a
    end

    def if_match
      requirement = @method.if_match.required ? "Required" : "Optional"
      "#{requirement}. Pass the ETag, or the model you read, as `if_match:`; a stale one raises " \
        "`PreconditionFailedError`"
    end

    def parameter_table
      parameters = YardTags.parameters(@method)
      return "Takes only `request_options:`." if parameters.empty?

      rows = parameters.map do |param|
        name = @method.path_params.include?(param) ? param.ruby : "#{param.ruby}:"
        ["`#{name}`", "`#{YardTags.type(@method, param)}`", param.required ? "Yes" : "", YardTags.description(param)]
      end
      [%w[Parameter Type Required Description], %w[--- --- --- ---], *rows].map do |cells|
        "| #{cells.map { |cell| cell.split.join(" ").gsub("|", "\\|") }.join(" | ")} |"
      end.join("\n")
    end
  end
end
