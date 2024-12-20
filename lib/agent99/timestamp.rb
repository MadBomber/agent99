# lib/agent99/timestamp.rb

class Agent99::Timestamp
  attr_reader :ts, :utc

  # regardless of the timezone of "now"
  # timestamps (@ts) is maintained in UTC microseconds
  # @ts is the Integer number of UTC-based microseconds since EPOCH
  #
  def initialize(now=Time.now)
    if now.is_a? Time
      @ts   = self.class.utc2ts(now.utc)
      @utc  = now.utc
    elsif now.is_a? Integer
      @utc  = self.class.ts2utc(now)
      @ts   = now
    else
      raise ArgumentError, "Expected ether a Time or Integer"
    end
  end

  def to_i    = @ts
  def to_utc  = @utc

  class << self
    def utc2ts(now=Time.now.utc)
      # NOTE: This is faster that bit shifting by the smallest of measures
      now.to_i * 1_000_000 + now.usec
    end

    def ts2utc(microseconds)
      # NOTE: This is an order of magitude faster than not bit shifting
      Time.at(microseconds >> 20, microseconds & 0xFFFFF).utc # Masking to get the last 20 bits  
    end
  end
end
