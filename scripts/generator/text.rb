# frozen_string_literal: true

module SdkGenerator
  # Source text helpers. Generated code is built as unindented chunks of
  # whole lines ("...\n"), indented where they are placed; +column+
  # arguments give the column a chunk will end up at, for wrapping.
  module Text
    BANNER = "# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`."
    RUBY_HEADER = "# frozen_string_literal: true\n\n#{BANNER}\n\n".freeze
    COMMENT_WIDTH = 100
    LINE_WIDTH = 120

    module_function

    def indent(text, by)
      text.lines.map { |line| line == "\n" ? line : (" " * by) + line }.join
    end

    # Wraps +body+ in +opening+ and "end", indented one level.
    def block(opening, body)
      "#{opening}\n#{indent(body, 2)}end\n"
    end

    # A comment block from paragraphs, wrapped; nil and blank paragraphs are
    # dropped. Lines inside a paragraph (Markdown lists) are kept.
    def comment(paragraphs, column)
      kept = paragraphs.compact.map(&:strip).reject(&:empty?)
      lines = kept.join("\n\n").split("\n").flat_map { |line| wrap_words(line.strip, COMMENT_WIDTH - column - 2) }
      lines.map { |line| line.empty? ? "#\n" : "# #{line}\n" }.join
    end

    def wrap_words(line, width)
      line.split.each_with_object([+""]) do |word, lines|
        if lines.last.empty?
          lines.last << word
        elsif lines.last.length + 1 + word.length > width
          lines << word.dup
        else
          lines.last << " " << word
        end
      end
    end

    # +head+, +items+ joined with ", ", then +tail+, packed onto lines that
    # fit LINE_WIDTH at +column+, continuation lines aligned under the
    # first item. Returns one or more lines.
    def pack(head, items, tail, column)
      return "#{head}#{tail}\n" if items.empty?

      pieces = [*items[...-1].map { |item| "#{item}," }, items.last + tail]
      continuation = " " * head.length
      pieces.drop(1).each_with_object([head + pieces.first]) do |piece, lines|
        next lines << (continuation + piece) if column + lines.last.length + piece.length >= LINE_WIDTH

        lines.last << " " << piece
      end.join("\n") << "\n"
    end

    def article(word)
      word.match?(/\A[AEIOU]/) ? "An" : "A"
    end

    def literal(value)
      value.inspect
    end

    def require_lines(names)
      names.map { |name| "require_relative #{literal(name)}\n" }.join
    end
  end
end
