# frozen_string_literal: true

# The fenced ruby blocks of the README, for the tests that compile and run
# them. Each block must follow a "<!-- sample: id -->" line and is named by
# its id. A block without a tag is kept with a nil id so a test can name it.
module DocSamples
  ROOT = File.expand_path("../..", __dir__)
  DOCUMENTS = [File.join(ROOT, "README.md")].freeze

  Sample = Data.define(:id, :code, :file, :line)

  def self.all
    @all ||= DOCUMENTS.flat_map { |file| samples_in(file) }
  end

  def self.find(id)
    all.find { |sample| sample.id == id }
  end

  def self.samples_in(file)
    lines = File.readlines(file)
    lines.each_index.filter_map do |index|
      next unless lines[index].start_with?("```ruby")

      tag = lines[index - 1][/\A<!-- sample: ([\w-]+) -->/, 1]
      body = lines[(index + 1)..].take_while { |line| !line.start_with?("```") }
      Sample.new(id: tag, code: body.join, file:, line: index + 2)
    end
  end
end
