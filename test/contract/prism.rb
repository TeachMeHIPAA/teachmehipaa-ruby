# frozen_string_literal: true

require "json"
require "socket"
require "tmpdir"

# Runs one Prism mock of the vendored developer spec for the whole contract
# run, and stops it when Minitest finishes.
#
# Prism serves static responses built from the spec's schemas. Neither
# --errors nor --dynamic is used: both make Prism fail on its own generated
# responses (static strings ignore +pattern+; dynamic numbers break OpenAPI
# 3.1 +exclusiveMinimum+), which says nothing about the SDK. Prism still
# answers a request that breaks the spec with a 4xx, which the client
# raises, and names each broken rule in the sl-violations header, which
# Violations collects so a test fails on any of them.
module Prism
  ROOT = File.expand_path("../..", __dir__)
  SPEC = "openapi/openapi.developer.json"
  PACKAGE = "@stoplight/prism-cli@5.16.0"
  # The first run downloads Prism through npx.
  STARTUP_TIMEOUT = 180

  module_function

  # The mock's base URL, starting Prism on the first call. Prism serves the
  # spec's paths without the server's /v1 prefix, so this is the bare host.
  def base_url
    @base_url ||= start
  end

  def start
    npx = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).map { |dir| File.join(dir, "npx") }
             .find { |path| File.executable?(path) }
    raise "the contract suite needs Node.js: npx is not on PATH" if npx.nil?

    port = free_port
    log = File.join(Dir.mktmpdir("prism"), "prism.log")
    # npx runs Prism as a grandchild; a process group of its own lets the
    # teardown stop the whole tree.
    pid = Process.spawn(npx, "--yes", PACKAGE, "mock", SPEC, "-h", "127.0.0.1", "-p", port.to_s,
                        chdir: ROOT, out: log, err: %i[child out], pgroup: true)
    Minitest.after_run { stop(pid) }
    wait_until_listening(pid, log)
    "http://127.0.0.1:#{port}"
  end

  # Releasing the port before Prism binds it is racy in theory, but Prism
  # binds within moments and the suite owns the machine in CI.
  def free_port
    server = TCPServer.new("127.0.0.1", 0)
    server.addr[1]
  ensure
    server&.close
  end

  def wait_until_listening(pid, log)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + STARTUP_TIMEOUT
    until File.read(log).include?("Prism is listening")
      raise "Prism exited:\n#{File.read(log)}" if Process.waitpid(pid, Process::WNOHANG)
      raise "Prism did not start:\n#{File.read(log)}" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.2
    end
  end

  def stop(pid)
    Process.kill("TERM", -pid)
    Process.wait(pid)
  rescue Errno::ESRCH, Errno::ECHILD
    nil
  end

  # A transport that sends through Net::HTTP and records each request
  # violation Prism reports, as "METHOD url: location message". Violations
  # in Prism's own generated responses are left out: they come from its
  # example generator, not from anything the client sent.
  class Violations
    attr_reader :found

    def initialize(transport = TeachMeHipaa::Transport::NetHttp.new)
      @transport = transport
      @found = []
    end

    def call(request, &stream)
      return record(request, @transport.call(request)) unless stream

      @transport.call(request) { |response| stream.call(record(request, response)) }
    end

    private

    def record(request, response)
      header = response.headers["sl-violations"]
      return response if header.nil?

      JSON.parse(header).each do |violation|
        next unless violation["location"].first == "request"

        @found << "#{request.http_method} #{request.url}: #{violation["location"].join(".")} #{violation["message"]}"
      end
      response
    end
  end
end
