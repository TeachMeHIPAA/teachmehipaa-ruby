# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # Sends requests to the client's base URL through its transport, with
    # the headers every request carries, and logs each exchange when a
    # logger is set. Logs never include bodies, query strings or headers
    # (ADR-0007): bodies and queries can carry Learner names and emails.
    #
    # @api private
    class Connection
      # What Net::HTTP (and transports built on sockets) raise when no
      # response arrives. Timeout::Error covers the open, read and write
      # timeouts.
      NETWORK_ERRORS = [
        IOError,
        SystemCallError,
        SocketError,
        OpenSSL::SSL::SSLError,
        Net::ProtocolError,
        Net::HTTPBadResponse,
      ].freeze

      # Raised in place of the connection error when a download fails after
      # its block received bytes, so the call ends instead of retrying.
      class Interrupted < StandardError
        attr_reader :error

        def initialize(error)
          @error = error
          super(error.message)
        end
      end

      attr_reader :config

      def initialize(config, transport)
        @config = config
        @transport = transport
      end

      # +stream+, for a download given a block, receives each response's
      # status and headers and returns the block for its chunks, or nil to
      # read the body whole (see BodyReader).
      def request(method:, path:, query: {}, headers: {}, body: nil, timeout: nil, stream: nil)
        request = Transport::Request.new(
          http_method: method,
          url: url(path, query),
          headers: { "accept" => "application/json", "user-agent" => config.user_agent }
            .merge(headers.transform_keys { |name| name.to_s.downcase }),
          body:,
          timeout: timeout || config.timeout,
        )
        started = config.clock.call
        response = normalize(stream ? send_streaming(request, BodyReader.new(stream)) : send_once(request))
        log(request, response, started)
        response
      end

      def inspect
        "#<#{self.class.name} base_url=#{config.base_url.inspect}>"
      end

      private

      def send_once(request)
        @transport.call(request)
      rescue APIConnectionError
        raise
      rescue Timeout::Error, *NETWORK_ERRORS => e
        raise connection_error(e)
      end

      # A transport that ignores the block returns the whole response instead.
      def send_streaming(request, reader)
        response = @transport.call(request) { |streaming| reader.read(streaming) }
        reader.response || reader.read(response)
      rescue APIConnectionError => e
        raise reader.started? ? Interrupted.new(e) : e
      rescue Timeout::Error, *NETWORK_ERRORS => e
        raise if reader.block_failed?

        raise connection_error(e) unless reader.started?

        raise Interrupted, APIConnectionError.new("The connection to the TeachMeHIPAA API was lost " \
                                                  "partway through the download: #{e.message}")
      end

      def connection_error(error)
        return APITimeoutError.new("The request to the TeachMeHIPAA API timed out.") if error.is_a?(Timeout::Error)

        APIConnectionError.new("Could not reach the TeachMeHIPAA API: #{error.message}")
      end

      def url(path, query)
        present = query.compact
        return config.base_url + path if present.empty?

        "#{config.base_url}#{path}?#{URI.encode_www_form(present)}"
      end

      def normalize(response)
        Transport::Response.new(
          status: response.status,
          headers: response.headers.to_h { |name, value| [name.to_s.downcase, value] }.freeze,
          body: response.body.to_s,
        )
      end

      def log(request, response, started)
        return if config.logger.nil?

        elapsed_ms = ((config.clock.call - started) * 1000).round
        config.logger.info(
          "teachmehipaa.request method=#{request.http_method} path=#{URI(request.url).path} " \
          "status=#{response.status} elapsed_ms=#{elapsed_ms} " \
          "request_id=#{response.headers["x-request-id"]}",
        )
      end
    end
  end
end
