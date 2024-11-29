require 'benchmark'
require_relative 'lib/ai_agent/timestamp'

# Number of iterations for the benchmark
iterations = 1_000_000

# Create a Time object for testing
time_now = Time.now.utc

Benchmark.bm(20) do |x|
  x.report("utc2ts:") do
    iterations.times { AiAgent::Timestamp.utc2ts(time_now) }
  end

  x.report("ts2utc:") do
    ts = AiAgent::Timestamp.utc2ts(time_now)
    iterations.times { AiAgent::Timestamp.ts2utc(ts) }
  end

  x.report("bs_utc2ts:") do
    iterations.times { AiAgent::Timestamp.bs_utc2ts(time_now) }
  end

  x.report("bs_ts2utc:") do
    ts = AiAgent::Timestamp.bs_utc2ts(time_now)
    iterations.times { AiAgent::Timestamp.bs_ts2utc(ts) }
  end
end
