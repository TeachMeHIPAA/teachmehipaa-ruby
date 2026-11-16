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

    # Counts the items rather than listing them.
    # @return [String]
    def inspect
      "#<#{self.class.name} items=#{items.length} next_cursor=#{next_cursor.inspect}>"
    end
  end

  # A success with no body, such as a delete's 204.
  EmptyResponse = Data.define(:last_response)

  # The 304 a retrieve returns when given +if_none_match:+ and the object
  # still has that ETag: keep using the copy you hold.
  #
  #   result = client.courses.retrieve(id, if_none_match: cached)
  #   course = result.not_modified? ? cached : result
  #
  # Every returned model answers +not_modified?+ with false.
  NotModified = Data.define(:last_response) do
    def not_modified? = true
  end

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

  # What a download given a block returns once the block has every chunk:
  # the file's +content_type+ and +filename+ (nil when the API names none).
  #
  #   File.open("certificate.pdf", "wb") do |file|
  #     client.certificates.download_pdf(certificate_id) { |chunk| file.write(chunk) }
  #   end
  StreamedResponse = Data.define(:content_type, :filename, :last_response)

  module Core
    # Reads a success into what a resource method returns, by the IR's
    # response kind.
    #
    # @api private
    module Responses
      # What reading needs besides the response: +model+ reads the body (each
      # item, for a page; an Operation class, for an operation), +accept+ is
      # a binary's promised media type, +fetch_next+ is a page's means to
      # fetch the page after it, and +requestor+ is what an Operation polls
      # through.
      Reading = Data.define(:model, :accept, :fetch_next, :requestor)

      module_function

      def read(response, kind, reading)
        last_response = LastResponse.from(response)
        # Only a call that sent If-None-Match is handed a 304.
        return NotModified.new(last_response:) if response.status == 304

        READERS.fetch(kind).call(response, last_response, reading)
      end

      def success?(status)
        (200..299).cover?(status)
      end

      def media_type?(content_type, accept)
        Json.media_type(content_type) == accept.downcase
      end

      # A binary success must carry the type the IR promises: unknown paths
      # answer 200 with an HTML page, which must not be handed back as a PDF.
      def check_media_type(response, accept)
        return if media_type?(response.headers["content-type"], accept)

        raise APIError.unexpected(response, expected: accept)
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

      # By response kind (the IR's, plus :streamed for a download given a
      # block), what a success reads into.
      READERS = {
        model: lambda do |response, last_response, reading|
          reading.model.new(Json.success_body(response), last_response:)
        end,
        # +created+ is not on the wire: 201 created the Learner, 200 found it
        # (grilling Q25).
        write_result: lambda do |response, last_response, reading|
          reading.model.new(Json.success_body(response).merge("created" => response.status == 201), last_response:)
        end,
        operation: lambda do |response, last_response, reading|
          reading.model.new(Json.success_body(response), last_response:, requestor: reading.requestor)
        end,
        page: lambda do |response, last_response, reading|
          body = Json.success_body(response)
          Page.new(items: Array(body["items"]).map { |item| reading.model.new(item) },
                   next_cursor: body["nextCursor"], last_response:, fetch_next: reading.fetch_next)
        end,
        empty: ->(_response, last_response, _reading) { EmptyResponse.new(last_response:) },
        binary: lambda do |response, last_response, reading|
          check_media_type(response, reading.accept)
          BinaryResponse.new(data: response.body.b, content_type: response.headers["content-type"],
                             filename: filename(response.headers["content-disposition"]), last_response:)
        end,
        # The block already has the bytes; a body read whole here was not the
        # promised type.
        streamed: lambda do |response, last_response, reading|
          check_media_type(response, reading.accept)
          StreamedResponse.new(content_type: response.headers["content-type"],
                               filename: filename(response.headers["content-disposition"]), last_response:)
        end,
      }.freeze
    end
  end
end
