# frozen_string_literal: true

require_relative "test_helper"

# Every relative link in the hand-written docs and the generated reference
# points at a file in the repository, and every #fragment at a heading in
# its target, using GitHub's heading anchors (the YARD build translates
# them; see scripts/yard_links.rb).
class DocLinksTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  DOCUMENTS = ["README.md", "CONTRIBUTING.md", "docs/README.md", "docs/reference/resources.md",
               "examples/README.md", *Dir.glob("docs/guides/*.md", base: ROOT)].freeze
  LINK = /\]\(([^)\s]+)\)/

  def test_every_relative_link_resolves
    broken = DOCUMENTS.flat_map do |document|
      links(document).filter_map { |target| "#{document} -> #{target}" unless resolves?(document, target) }
    end

    assert_empty broken, "broken links"
  end

  def test_checks_every_guide
    assert_operator DOCUMENTS.count { |document| document.start_with?("docs/guides/") }, :>=, 8
  end

  private

  # Links outside fenced code blocks, skipping absolute URLs.
  def links(document)
    prose = File.read(File.join(ROOT, document), encoding: "UTF-8").gsub(/^```.*?^```/m, "")
    prose.scan(LINK).flatten.grep_v(/\A[a-z][a-z0-9+.-]*:/i)
  end

  def resolves?(document, target)
    path, fragment = target.split("#", 2)
    file = path.empty? ? File.join(ROOT, document) : File.expand_path(path, File.dirname(File.join(ROOT, document)))
    return false unless File.exist?(file)
    return true if fragment.nil? || File.directory?(file)

    anchors(file).include?(fragment)
  end

  def anchors(file)
    File.read(file, encoding: "UTF-8").gsub(/^```.*?^```/m, "").scan(/^#+ (.+)$/).flatten.map do |heading|
      heading.delete("`*").downcase.gsub(/[^\w\- ]/, "").tr(" ", "-")
    end
  end
end
