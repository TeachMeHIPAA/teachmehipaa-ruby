# frozen_string_literal: true

# YARD loads this file (see .yardopts) once per option pass.
return if defined?(TeachMeHipaaYardLinks)

# Used when YARD builds the API reference. The README and the guides link to
# each other, and to the rest of the repository, with relative Markdown paths
# and GitHub's heading anchors, which work on GitHub. On the published site,
# a link to another published Markdown file goes to that file's page, a link
# to any other repository path goes to it on GitHub, and heading anchors are
# translated to the ids YARD gives headings.
module TeachMeHipaaYardLinks
  REPOSITORY = "https://github.com/TeachMeHIPAA/teachmehipaa-ruby/blob/main/"
  RELATIVE_LINK = /href="(?![a-z][a-z0-9+.-]*:)([^"#]*)(?:#([^"]*))?"/i

  # Rewrites the links Markdown itself made, before YARD adds its own links
  # to code objects.
  def html_markup_markdown(text)
    html = super
    file = options.file if options.respond_to?(:file)
    return html unless file

    html.gsub(RELATIVE_LINK) do
      path, fragment = Regexp.last_match.captures
      %(href="#{path.empty? ? "##{yard_anchor(file, fragment)}" : published_url(file, path, fragment)}")
    end
  end

  private

  def published_url(from, path, fragment)
    target = File.expand_path(path, File.join("/", File.dirname(from.filename))).delete_prefix("/")
    published = options.files.find { |file| file.filename == target }
    return "#{REPOSITORY}#{target}#{"##{fragment}" if fragment}" unless published

    url_for_file(published, fragment && yard_anchor(published, fragment))
  end

  # GitHub's anchor for a heading is its text lower-cased, with spaces as
  # hyphens and other punctuation dropped; YARD's id keeps the case and turns
  # anything but letters, digits and hyphens into "_".
  def yard_anchor(file, fragment)
    headings = file.contents.scan(/^#+ (.+)$/).flatten.map { |heading| heading.delete("`*") }
    heading = headings.find { |text| text.downcase.gsub(/[^\w\- ]/, "").tr(" ", "-") == fragment }
    heading ? heading.gsub(/[^a-z0-9-]/i, "_") : fragment
  end
end

YARD::Templates::Helpers::HtmlHelper.prepend(TeachMeHipaaYardLinks)
