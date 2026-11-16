# frozen_string_literal: true

# The fenced ruby blocks of the README and the guides in docs/guides, for
# the tests that compile and run them. Each block must follow a
# "<!-- sample: id -->" line. A README sample is named by its id; a guide's
# by "<guide>/<id>", such as "rails/webhook-controller". A block without a
# tag is kept with a nil id so a test can name it.
module DocSamples
  ROOT = File.expand_path("../..", __dir__)
  DOCUMENTS = [File.join(ROOT, "README.md"), *Dir[File.join(ROOT, "docs/guides/*.md")]].freeze

  Sample = Data.define(:id, :code, :file, :line)

  def self.all
    @all ||= DOCUMENTS.flat_map { |file| samples_in(file) }
  end

  def self.find(id)
    all.find { |sample| sample.id == id }
  end

  def self.samples_in(file)
    guide = File.basename(file, ".md") unless file.end_with?("/README.md")
    lines = File.readlines(file)
    lines.each_index.filter_map do |index|
      next unless lines[index].start_with?("```ruby")

      tag = lines[index - 1][/\A<!-- sample: ([\w-]+) -->/, 1]
      body = lines[(index + 1)..].take_while { |line| !line.start_with?("```") }
      Sample.new(id: tag && [guide, tag].compact.join("/"), code: body.join, file:, line: index + 2)
    end
  end
end
