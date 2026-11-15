# frozen_string_literal: true

require "json"
require "uri"

# A scripted stand-in for the API, plugged in through the client's transport
# seam so tests drive the public client end to end. Replies are scripted per
# (method, path) and served in order; the last one repeats. Every request is
# recorded for wire assertions. Called with a block, it streams the body to
# the block in +chunk_size+ pieces, as Transport::NetHttp does.
class FakeTransport
  # A body whose connection drops after +sent+ has been read.
  Dropped = Data.define(:sent) do
    def each
      yield sent
      raise Errno::ECONNRESET, "connection reset by peer"
    end
  end

  Reply = Data.define(:status, :body, :headers, :content_type) do
    def self.json(body, status: 200, headers: {}, content_type: "application/json")
      new(status:, body: JSON.generate(body), headers:, content_type:)
    end

    # A reply with no body and no Content-Type, such as a 204.
    def self.empty(status: 204, headers: {})
      new(status:, body: "", headers:, content_type: nil)
    end

    def to_response(body = self.body)
      TeachMeHipaa::Transport::Response.new(
        status:,
        headers: { "content-type" => content_type }.compact.merge(headers),
        body:,
      )
    end
  end

  attr_reader :requests

  def initialize(base_url = Fixtures::LIVE_BASE, chunk_size: 16_384)
    @base_path = URI(base_url).path.chomp("/")
    @chunk_size = chunk_size
    @routes = Hash.new { |routes, key| routes[key] = [] }
    @requests = []
    @lock = Mutex.new
  end

  # A reply is a Reply, or a callable that receives the request and returns one.
  def on(method, path, reply)
    @routes[[method, @base_path + path]] << reply
    self
  end

  def replace(method, path, reply)
    @routes[[method, @base_path + path]] = [reply]
    self
  end

  def requests_to(method, path)
    full = @base_path + path
    @lock.synchronize { @requests.select { |r| r.http_method == method && URI(r.url).path == full } }
  end

  def call(request, &stream)
    reply = @lock.synchronize do
      @requests << request
      queue = @routes[[request.http_method, URI(request.url).path]]
      raise "unscripted request #{request.http_method} #{request.url}" if queue.empty?

      queue.length > 1 ? queue.shift : queue.first
    end
    reply = reply.call(request) if reply.respond_to?(:call)
    return stream.call(reply.to_response(chunks(reply.body))) if stream
    raise Errno::ECONNRESET, "connection reset by peer" if reply.body.is_a?(Dropped)

    reply.to_response
  end

  private

  def chunks(body)
    return body unless body.is_a?(String)

    (0...body.bytesize).step(@chunk_size).map { |offset| body.byteslice(offset, @chunk_size).b }
  end
end

class FakeClock
  attr_reader :now

  def initialize(now = 1_000.0)
    @now = now
  end

  def call
    @now
  end

  def advance(seconds)
    @now += seconds
  end
end

# Records each wait instead of waiting, and moves +clock+ (a FakeClock)
# forward by it when given one.
class FakeSleep
  attr_reader :waits

  def initialize(clock = nil)
    @waits = []
    @clock = clock
  end

  def call(seconds)
    @waits << seconds
    @clock&.advance(seconds)
  end
end

class RecordingLogger
  attr_reader :lines

  def initialize
    @lines = []
  end

  %i[debug info warn error].each do |level|
    define_method(level) { |message = nil, &block| @lines << (message || block.call) }
  end
end
