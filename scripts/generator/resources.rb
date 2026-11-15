# frozen_string_literal: true

module SdkGenerator
  # One resource class per resource in the client's tree (Ruby and RBS), the
  # Root module the client includes, and the resources.rb index.
  class Resources
    LIB = "lib/teachmehipaa/resources"
    SIG = "sig/teachmehipaa/resources"
    # Resources with hand-written methods, by IR path. Their generated class
    # is <Name>Base; extensions/<file>.rb subclasses it under the plain name,
    # which the client exposes, and sig/teachmehipaa/extensions/<file>.rbs
    # signs it.
    EXTENDED_RESOURCES = %w[events].freeze

    Node = Data.define(:path, :operations, :children) do
      def class_name = Naming.resource_class(path)
      def accessor = Naming.snake(path.last)
      def file = Naming.snake(class_name)
      def extended? = EXTENDED_RESOURCES.include?(path.join("."))
      def generated_class = extended? ? "#{class_name}Base" : class_name
    end

    def initialize(ir)
      @ir = ir
    end

    def files
      check_extended
      files = flatten(tree).each_with_object({}) do |node, all|
        methods = node.operations.map { |method| ApiMethod.new(@ir, node.path, method) }
        all["#{LIB}/#{node.file}.rb"] = ruby_resource(node, methods)
        all["#{SIG}/#{node.file}.rbs"] = rbs_resource(node, methods)
      end
      files.merge("#{LIB}/root.rb" => ruby_root, "#{SIG}/root.rbs" => rbs_root).then { |all| all.merge(index(all)) }
    end

    # The extensions load after every generated class they may build on.
    def index(files)
      names = files.keys.grep(/\.rb\z/).sort.map { |path| "resources/#{File.basename(path, ".rb")}" }
      extensions = flatten(tree).select(&:extended?).map { |node| "extensions/#{node.file}" }
      { "lib/teachmehipaa/resources.rb" => Text::RUBY_HEADER + Text.require_lines(names + extensions) }
    end

    private

    def check_extended
      missing = EXTENDED_RESOURCES - flatten(tree).map { |node| node.path.join(".") }
      raise ArgumentError, "extended resource(s) not in the IR: #{missing.join(", ")}" if missing.any?
    end

    def tree
      @tree ||= begin
        paths = @ir.resources.flat_map do |resource|
          (1..resource.fetch("path").length).map { |n| resource.fetch("path").first(n) }
        end.uniq
        methods = @ir.resources.to_h { |resource| [resource.fetch("path"), resource.fetch("methods")] }
        paths.select { |path| path.length == 1 }.sort.map { |path| node(path, paths, methods) }
      end
    end

    def node(path, paths, methods)
      children = paths.select { |other| other.length == path.length + 1 && other.first(path.length) == path }
      Node.new(path:, operations: (methods[path] || []).sort_by { |method| method.fetch("name") },
               children: children.sort.map { |child| node(child, paths, methods) })
    end

    def flatten(nodes)
      nodes.flat_map { |node| [node, *flatten(node.children)] }
    end

    def wrap(body)
      Text::RUBY_HEADER + Text.block("module TeachMeHipaa", Text.block("module Resources", body))
    end

    def wrap_rbs(body)
      "#{Text::BANNER}\n#{Text.block("module TeachMeHipaa", Text.block("module Resources", body))}"
    end

    def class_doc(node)
      accessor = node.path.map { |segment| Naming.snake(segment) }.join(".")
      return Text.comment(["The methods under +client.#{accessor}+."], 4) unless node.extended?

      Text.comment(["The generated methods under +client.#{accessor}+. The client exposes the hand-written " \
                    "subclass #{node.class_name} in lib/teachmehipaa/extensions/#{node.file}.rb."], 4)
    end

    def ruby_resource(node, methods)
      sections = [*ruby_children(node), *methods.map { |method| ruby_method(method) }]
      wrap(class_doc(node) + Text.block("class #{node.generated_class} < Core::Resource", sections.join("\n")))
    end

    def ruby_children(node)
      return [] if node.children.empty?

      assignments = node.children.map { |child| "@#{child.accessor} = #{child.class_name}.new(requestor)\n" }
      [Text.pack("attr_reader ", node.children.map { |child| ":#{child.accessor}" }, "", 6),
       Text.block("def initialize(requestor)", "super\n#{assignments.join}")]
    end

    def ruby_method(method)
      signature = Text.pack("def #{method.ruby_name}(", method.ruby_parameters, ")", 6).chomp
      Text.comment(method.doc, 6) + Text.block(signature, RequestCall.new(method).source)
    end

    def rbs_resource(node, methods)
      readers = node.children.map { |child| "attr_reader #{child.accessor}: #{child.class_name}\n" }
      signatures = methods.map { |method| RbsSignature.new(method).source }
      sections = [*(readers.join unless readers.empty?), *signatures]
      wrap_rbs(class_doc(node) + Text.block("class #{node.generated_class} < Core::Resource", sections.join("\n")))
    end

    def ruby_root
      assignments = tree.map { |node| "@#{node.accessor} = #{node.class_name}.new(requestor)\n" }
      body = "#{Text.pack("attr_reader ", tree.map { |node| ":#{node.accessor}" }, "", 6)}\nprivate\n\n" \
             "#{Text.block("def build_resources(requestor)", assignments.join)}"
      wrap("# The resource accessors on TeachMeHipaa::Client.\n#{Text.block("module Root", body)}")
    end

    def rbs_root
      readers = tree.map { |node| "attr_reader #{node.accessor}: #{node.class_name}\n" }
      wrap_rbs(Text.block("module Root", readers.join))
    end
  end
end
