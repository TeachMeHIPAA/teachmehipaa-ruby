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
      attr_reader :config

      def initialize(config, transport)
        @config = config
        @transport = transport
      end

      def request(method:, path:, query: {}, headers: {}, body: nil, timeout: nil)
        request = Transport::Request.new(
          http_method: method,
          url: url(path, query),
          headers: { "accept" => "application/json", "user-agent" => config.user_agent }
            .merge(headers.transform_keys { |name| name.to_s.downcase }),
          body:,
          timeout: timeout || config.timeout,
        )
        started = config.clock.call
        response = normalize(@transport.call(request))
        log(request, response, started)
        response
      end

      def inspect
        "#<#{self.class.name} base_url=#{config.base_url.inspect}>"
      end

      private

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
