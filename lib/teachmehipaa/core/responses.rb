# frozen_string_literal: true

module TeachMeHipaa
  # One page of a list. Pass #next_cursor back as +cursor:+ for the next
  # page; it is nil on the last one.
  class Page
    attr_reader :items, :next_cursor, :last_response

    def initialize(items:, next_cursor:, last_response:)
      @items = items.freeze
      @next_cursor = next_cursor
      @last_response = last_response
      freeze
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

      def read(response, kind, model, accept)
        last_response = LastResponse.from(response)
        case kind
        when :empty then empty(response, last_response)
        when :binary then binary(response, accept, last_response)
        when :page then page(response, model, last_response)
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

      def page(response, model, last_response)
        body = Json.success_body(response)
        Page.new(items: Array(body["items"]).map { |item| model.new(item) }, next_cursor: body["nextCursor"],
                 last_response:)
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
