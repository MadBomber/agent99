# frozen_string_literal: true

require "test_helper"

class TestTimestamp < Minitest::Test
  # 2026-11-09 12:34:56.789012 UTC
  KNOWN_TIME = Time.utc(2026, 11, 9, 12, 34, 56, 789_012)
  KNOWN_TS   = 1_794_227_696_789_012

  def setup; end
  def teardown; end

  def test_ts2utc_returns_utc
    assert_predicate Agent99::Timestamp.ts2utc(KNOWN_TS), :utc?
  end

  def test_round_trip_preserves_microseconds
    now = Time.now.floor(6)
    ts  = Agent99::Timestamp.new(now).to_i

    assert_equal now.getutc, Agent99::Timestamp.new(ts).to_utc
  end

  def test_time_constructor_truncates_to_microseconds
    stamp = Agent99::Timestamp.new(Time.at(1_700_000_000, 123_456_789, :nsec))

    assert_equal Time.at(1_700_000_000, 123_456).utc, stamp.to_utc
  end

  def test_time_constructor_leaves_callers_time_alone
    local = Time.new(2026, 11, 9, 6, 34, 56, "-06:00")
    Agent99::Timestamp.new(local)

    refute_predicate local, :utc?
  end

  def test_time_constructor_converts_local_time_to_utc
    local = Time.new(2026, 11, 9, 6, 34, 56.789012r, "-06:00")
    stamp = Agent99::Timestamp.new(local)

    assert_equal KNOWN_TS, stamp.to_i
    assert_equal KNOWN_TIME, stamp.to_utc
    assert_same stamp.to_utc, stamp.utc
  end

  def test_integer_constructor
    stamp = Agent99::Timestamp.new(KNOWN_TS)

    assert_equal KNOWN_TS, stamp.to_i
    assert_equal KNOWN_TIME, stamp.to_utc
  end

  def test_rejects_other_types
    error = assert_raises(ArgumentError) { Agent99::Timestamp.new("2026-11-09") }
    assert_match(/got String/, error.message)
    assert_raises(ArgumentError) { Agent99::Timestamp.new(1.5) }
  end
end
