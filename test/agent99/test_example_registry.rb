# frozen_string_literal: true

require "minitest/autorun"
require "net/http"
require "rbconfig"
require "socket"

# Issue #105: one TERM must stop examples/registry.rb; an explicit run! on
# top of Sinatra's classic-style auto-run started the server a second time.
class TestExampleRegistry < Minitest::Test
  ROOT     = File.expand_path("../..", __dir__)
  REGISTRY = File.join(ROOT, "examples", "registry.rb")

  def free_port
    server = TCPServer.new("127.0.0.1", 0)
    server.addr[1]
  ensure
    server&.close
  end

  # The development bundle has no rackup, which Sinatra needs to serve, so
  # the registry runs outside the bundle as a user would run it.
  def spawn_registry(port)
    command = [RbConfig.ruby, REGISTRY, "-s", "webrick", "-p", port.to_s]
    options = { chdir: ROOT, out: File::NULL, err: File::NULL }
    return Process.spawn(*command, **options) unless defined?(Bundler)

    Bundler.with_unbundled_env { Process.spawn(*command, **options) }
  end

  def healthy?(port)
    Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/healthcheck")).is_a?(Net::HTTPSuccess)
  rescue SystemCallError, IOError
    false
  end

  def exited_within?(pid, seconds)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
    while Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      return true if Process.wait(pid, Process::WNOHANG)

      sleep 0.1
    end
    false
  end

  def test_term_stops_the_registry
    port = free_port
    pid  = spawn_registry(port)

    started = false
    100.times do
      break if (started = healthy?(port))
      skip "examples/registry.rb did not start (needs sinatra, rackup and webrick)" if exited_within?(pid, 0.1)
    end
    flunk "examples/registry.rb did not answer /healthcheck" unless started

    Process.kill("TERM", pid)

    assert exited_within?(pid, 5), "registry still running after TERM"
    refute healthy?(port), "registry still answering after TERM"
    pid = nil
  ensure
    if pid
      Process.kill("KILL", pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end
end
