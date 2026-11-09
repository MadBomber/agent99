# lib/agent99/timestamp.rb

class Agent99::Timestamp
  attr_reader :ts

  # regardless of the timezone of "now"
  # timestamps (@ts) is maintained in UTC microseconds
  # @ts is the Integer number of UTC-based microseconds since EPOCH
  #
  def initialize(now=Time.now)
    if now.is_a? Time
      @ts = self.class.utc2ts(now)
    elsif now.is_a? Integer
      @ts = now
    else
      raise ArgumentError, "Expected either a Time or Integer, got #{now.class}"
    end
  end

  def to_i    = @ts
  def to_utc  = @utc ||= self.class.ts2utc(@ts)
  alias utc to_utc

  class << self
    def utc2ts(now=Time.now)
      now.to_i * 1_000_000 + now.usec
    end

    def ts2utc(microseconds)
      # Inverse of utc2ts: split into whole seconds and leftover microseconds
      Time.at(*microseconds.divmod(1_000_000)).utc
    end
  end
end
