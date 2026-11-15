# frozen_string_literal: true

module TeachMeHipaa
  # One page of a list, as every list method returns it.
  #
  # Like Stripe's list objects, a page is Enumerable over its own #items
  # only: +each+, +map+ and +first+ never make a request. #auto_paging_each
  # iterates every item across this page and the pages after it, fetching
  # each page only when iteration reaches it:
  #
  #   client.learners.list(limit: 100).auto_paging_each { |learner| ... }
  #   client.learners.list.auto_paging_each.lazy.select(&:certificate).first(10)
  #
  # Later pages repeat the first call's filters, limit and request options;
  # the API, not the library, validates them. A page can hold fewer items
  # than the limit (even none) and still have a next page.
  class Page
    include Enumerable

    attr_reader :items, :next_cursor, :last_response

    # +fetch_next+ receives this page and returns the next one. A page built
    # without it (a test double, say) has no next page.
    def initialize(items:, next_cursor:, last_response:, fetch_next: nil)
      @items = items.freeze
      @next_cursor = next_cursor
      @last_response = last_response
      @fetch_next = fetch_next
      freeze
    end

    # Each item on this page only; see #auto_paging_each for every page.
    def each(&block)
      return enum_for(:each) { items.length } unless block

      items.each(&block)
      self
    end

    # Whether more items follow: the API sent a +next_cursor+.
    def next_page?
      !next_cursor.nil? && !@fetch_next.nil?
    end

    # Fetches the page after this one. On the last page it raises
    # StopIteration without a request; check #next_page? first.
    def next_page
      raise StopIteration, "this is the last page; check next_page? first" unless next_page?

      @fetch_next.call(self)
    end

    # Yields this page, then each page after it, fetched as the loop asks.
    # Without a block, returns an Enumerator.
    def each_page
      return enum_for(:each_page) unless block_given?

      page = self
      yield page
      while page.next_page?
        page = page.next_page
        yield page
      end
      self
    end

    # Yields every item on this page and the pages after it, fetching each
    # page only when the loop reaches it; breaking out stops the fetching.
    # Without a block, returns an Enumerator, so +lazy+, +first(n)+ and
    # +each_slice+ fetch only the pages they need.
    def auto_paging_each(&block)
      return enum_for(:auto_paging_each) unless block

      each_page { |page| page.items.each(&block) }
    end

    def inspect
      "#<#{self.class.name} items=#{items.length} next_cursor=#{next_cursor.inspect}>"
    end
  end

  # A success with no body, such as a delete's 204.
  EmptyResponse = Data.define(:last_response)

  # A file the API sent, such as a Certificate PDF. +data+ is the bytes as a
  # binary String; +content_type+ and +filename+ come from the response
  # headers (+filename+ is nil when the API names none).
  BinaryResponse = Data.define(:data, :content_type, :filename, :last_response) do
    # The bytes stay out of inspect output: a Certificate carries a person's
    # name.
    def inspect
      "#<#{self.class.name} content_type=#{content_type.inspect} filename=#{filename.inspect} " \
        "bytes=#{data.bytesize}>"
    end
  end

  module Core
    # Reads a success into what a resource method returns, by the IR's
    # response kind.
    #
    # @api private
    module Responses
      module_function

      # +fetch_next+ is the Page's means to fetch the page after it.
      def read(response, kind, model, accept, fetch_next: nil)
        last_response = LastResponse.from(response)
        case kind
        when :empty then empty(response, last_response)
        when :binary then binary(response, accept, last_response)
        when :page then page(response, model, last_response, fetch_next)
        when :write_result
          # Not on the wire: 201 created the Learner, 200 found it (grilling Q25).
          model.new(Json.success_body(response).merge("created" => response.status == 201), last_response:)
        else model.new(Json.success_body(response), last_response:)
        end
      end

      def empty(response, last_response)
        raise Error.from_response(response) unless success?(response)

        EmptyResponse.new(last_response:)
      end

      # A binary success must carry the type the IR promises: unknown paths
      # answer 200 with an HTML page, which must not be handed back as a PDF.
      def binary(response, accept, last_response)
        raise Error.from_response(response) unless success?(response)

        content_type = response.headers["content-type"]
        unless content_type.to_s.split(";").first.to_s.strip.casecmp?(accept)
          raise APIError.unexpected(response, expected: accept)
        end

        BinaryResponse.new(data: response.body.b, content_type:,
                           filename: filename(response.headers["content-disposition"]), last_response:)
      end

      def page(response, model, last_response, fetch_next)
        body = Json.success_body(response)
        Page.new(items: Array(body["items"]).map { |item| model.new(item) }, next_cursor: body["nextCursor"],
                 last_response:, fetch_next:)
      end

      # RFC 6266: the UTF-8 filename* when present, else the plain filename.
      def filename(content_disposition)
        header = content_disposition.to_s
        encoded = header[/filename\*=UTF-8''([^;\s]+)/i, 1]
        return URI.decode_www_form_component(encoded.tr("+", " ")) if encoded

        header[/filename="?([^";]+)"?/i, 1]
      rescue ArgumentError
        header[/filename="?([^";]+)"?/i, 1]
      end

      def success?(response)
        (200..299).cover?(response.status)
      end
    end
  end
end
