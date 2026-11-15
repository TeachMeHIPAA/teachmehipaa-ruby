# frozen_string_literal: true

module TeachMeHipaa
  # The HTTP seam. A transport is any object whose +call+ takes a
  # Transport::Request and returns a Transport::Response; pass one as
  # +transport:+ to add a proxy, mTLS or a test fake. The library owns
  # retries, so a transport sends each request exactly once. When no
  # response arrives it raises: Net::HTTP's own network and timeout errors
  # are recognised, and any transport may raise TeachMeHipaa::APIConnectionError
  # or TeachMeHipaa::APITimeoutError itself.
  module Transport
    # +http_method+ is an upper-case verb, +url+ is absolute, +headers+ is a Hash
    # with lower-case String keys, +body+ is a String or nil and +timeout+ is
    # in seconds.
    Request = Data.define(:http_method, :url, :headers, :body, :timeout)

    # +headers+ is a Hash with lower-case String keys; repeated headers are
    # joined with ", ".
    Response = Data.define(:status, :headers, :body)

    # The default transport, on the standard library's Net::HTTP.
    class NetHttp
      def call(request)
        uri = URI(request.url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = http.read_timeout = http.write_timeout = request.timeout
        http.max_retries = 0
        response = http.start { |connection| connection.request(net_request(request, uri)) }
        Response.new(status: response.code.to_i, headers: response.each_header.to_h,
                     body: response.body.to_s)
      end

      private

      def net_request(request, uri)
        net_request = Net::HTTPGenericRequest.new(
          request.http_method, !request.body.nil?, request.http_method != "HEAD", uri.request_uri,
          request.headers
        )
        net_request.body = request.body
        net_request
      end
    end
  end
end
