# frozen_string_literal: true

require "fileutils"
require "json"
require_relative "generator/schema"
require_relative "generator/naming"
require_relative "generator/text"
require_relative "generator/type_refs"
require_relative "generator/ir"
require_relative "generator/models"
require_relative "generator/scopes"
require_relative "generator/api_method"
require_relative "generator/request_call"
require_relative "generator/rbs_signature"
require_relative "generator/yard_tags"
require_relative "generator/sample_calls"
require_relative "generator/code_samples"
require_relative "generator/resources"

# Generates the resource and model layer and the API reference's Ruby
# samples from openapi/sdk-ir.json, the only input it reads (ADR-0001). Run it with `bundle exec rake generate`.
module SdkGenerator
  # Directories the generator owns outright: anything else in them is stale.
  DIRECTORIES = %w[
    lib/teachmehipaa/models lib/teachmehipaa/resources sig/teachmehipaa/models sig/teachmehipaa/resources
  ].freeze
  INDEXES = %w[lib/teachmehipaa/models.rb lib/teachmehipaa/resources.rb].freeze
  # Generated files outside those directories, beside hand-written ones.
  SINGLE_FILES = [*INDEXES, CodeSamples::PATH].freeze
  # Hand-written, never generated: one .rb and one .rbs per extended resource.
  EXTENSIONS = { "lib/teachmehipaa/extensions" => "rb", "sig/teachmehipaa/extensions" => "rbs" }.freeze

  module_function

  # The vendored IR, checked against its vendored schema.
  def load_ir(root)
    ir = JSON.parse(File.read(File.join(root, "openapi/sdk-ir.json"), encoding: "UTF-8"))
    schema = Schema.new(JSON.parse(File.read(File.join(root, "openapi/sdk-ir.schema.json"), encoding: "UTF-8")))
    problems = schema.errors(ir)
    raise ArgumentError, "openapi/sdk-ir.json does not match its schema:\n  #{problems.join("\n  ")}" if problems.any?

    ir
  end

  # Every generated file: path relative to the repo root => source. The
  # same IR always yields the same Hash.
  def generate(data)
    ir = Ir.new(data)
    Models.new(ir).files.merge(Resources.new(ir).files, CodeSamples.new(ir).files).sort.to_h
  end

  # The hand-written files each of Resources::EXTENDED_RESOURCES and
  # Models::EXTENDED_MODELS needs.
  def extension_files(root)
    resources = Resources::EXTENDED_RESOURCES.map { |path| Naming.snake(Naming.resource_class(path.split("."))) }
    models = Models::EXTENDED_MODELS.map { |name| Naming.snake(name) }
    (resources + models).flat_map do |file|
      EXTENSIONS.map { |directory, extension| File.join(root, directory, "#{file}.#{extension}") }
    end
  end

  # The generated files currently in the repo.
  def committed_paths(root)
    owned = DIRECTORIES.flat_map do |directory|
      path = File.join(root, directory)
      Dir.exist?(path) ? Dir.children(path).map { |name| "#{directory}/#{name}" } : []
    end
    owned + SINGLE_FILES.select { |path| File.exist?(File.join(root, path)) }
  end

  # Rewrites the generated files under +root+ and deletes stale ones.
  def write(root)
    missing = extension_files(root).reject { |path| File.exist?(path) }
    raise ArgumentError, "extended resources need hand-written #{missing.join(", ")}" if missing.any?

    ir = load_ir(root)
    files = generate(ir)
    stale = committed_paths(root) - files.keys
    stale.each { |path| File.delete(File.join(root, path)) }
    files.each do |path, source|
      FileUtils.mkdir_p(File.dirname(File.join(root, path)))
      File.write(File.join(root, path), source, encoding: "UTF-8")
    end
    "Generated #{files.size} files from IR #{ir.dig("source", "release")}; removed #{stale.size} stale."
  end
end
