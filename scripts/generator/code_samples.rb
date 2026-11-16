# frozen_string_literal: true

module SdkGenerator
  # docs/reference/code-samples.json: one complete Ruby sample per IR
  # operationId, which the TeachMeHIPAA API reference shows when a reader
  # picks Ruby. Where two methods share an operationId (enrollments.batch
  # and batch_by_filter, import and preview_import), the first in the IR
  # speaks for it.
  #
  # The method, its accessor and its positional ids come from the IR; the
  # keywords and the line that uses the result come from SampleCalls. A
  # keyword the method doesn't take, a missing required one, or an
  # operation without an entry stops the generator.
  class CodeSamples
    PATH = "docs/reference/code-samples.json"
    WIDTH = 80
    CREDENTIALED_CLIENT = <<~RUBY
      require "teachmehipaa"

      client = TeachMeHipaa::Client.new(
        client_id: ENV.fetch("TMH_CLIENT_ID"),
        client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
        environment: :sandbox,
      )
    RUBY
    PUBLIC_CLIENT = <<~RUBY
      require "teachmehipaa"

      client = TeachMeHipaa::Client.new(environment: :sandbox)
    RUBY

    def initialize(ir, calls: SampleCalls::CALLS)
      @ir = ir
      @calls = calls
    end

    def files
      document = { "language" => "ruby", "release" => @ir.data.dig("source", "release"), "samples" => samples }
      { PATH => "#{JSON.pretty_generate(document)}\n" }
    end

    # operationId => sample source, in operationId order.
    def samples
      methods = first_method_per_operation
      unknown = @calls.keys - methods.keys
      missing = methods.keys - @calls.keys
      raise ArgumentError, "SampleCalls::CALLS names no IR operation #{unknown.join(", ")}" if unknown.any?
      raise ArgumentError, "SampleCalls::CALLS needs #{missing.join(", ")}" if missing.any?

      methods.sort.to_h { |operation_id, (path, method)| [operation_id, source(path, method)] }
    end

    private

    def first_method_per_operation
      @ir.resources.each_with_object({}) do |resource, found|
        path = resource.fetch("path")
        resource.fetch("methods").each do |data|
          found[data.fetch("operationId")] ||= [path, ApiMethod.new(@ir, path, data)]
        end
      end
    end

    def source(path, method)
      entry = @calls.fetch(method.data.fetch("operationId"))
      check_keywords(method, entry.fetch(:args))
      client = method.public? ? PUBLIC_CLIENT : CREDENTIALED_CLIENT
      lines = [entry[:before], assignment(path, method, entry), entry.fetch(:use)].compact
      "#{client}\n#{lines.join("\n")}\n"
    end

    def check_keywords(method, args)
      name = method.data.fetch("operationId")
      known = (method.required_keywords + method.optional_keywords).map(&:ruby)
      unknown = args.keys.map(&:to_s) - known
      missing = method.required_keywords.map(&:ruby) - args.keys.map(&:to_s)
      raise ArgumentError, "#{name}'s sample passes #{unknown.join(", ")}, which it doesn't take" if unknown.any?
      raise ArgumentError, "#{name}'s sample leaves out required #{missing.join(", ")}" if missing.any?
    end

    # "result = client.resource.method(args)", one argument per line when
    # the call is wider than WIDTH.
    def assignment(path, method, entry)
      positional = method.path_params.map { |param| SampleCalls::PATH_VALUES.fetch(param.wire).inspect }
      keywords = entry.fetch(:args).map { |key, value| "#{key}: #{literal(value)}" }
      arguments = positional + keywords
      head = "#{entry.fetch(:result)} = #{Reference.accessor(path)}.#{method.ruby_name}"
      tail = entry[:chain].to_s
      one_line = arguments.empty? ? "#{head}#{tail}" : "#{head}(#{arguments.join(", ")})#{tail}"
      return one_line if one_line.length <= WIDTH

      "#{head}(\n#{arguments.map { |argument| "  #{argument},\n" }.join})#{tail}"
    end

    def literal(value)
      case value
      when SampleCalls::Raw then value.source
      when Array then "[#{value.map { |item| literal(item) }.join(", ")}]"
      when Hash then "{ #{value.map { |key, item| "#{key}: #{literal(item)}" }.join(", ")} }"
      else value.inspect
      end
    end
  end
end
