# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "securerandom"

class TestBinTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  # bin/test runs each file in a child process; no shared mock server needed.
  def setup; end

  def teardown; end

  def run_bin_test_with_probe(body)
    tag = "probe#{SecureRandom.hex(6)}"
    probe = File.join(ROOT, "test", "agent99", "test_#{tag}.rb")
    File.write(probe, body)

    Open3.capture2e(RbConfig.ruby, File.join(ROOT, "bin", "test"), "-p", tag)
  ensure
    File.delete(probe) if probe && File.exist?(probe)
  end

  def test_exits_non_zero_when_a_test_fails
    output, status = run_bin_test_with_probe(<<~RUBY)
      require "minitest/autorun"
      class FailingProbe < Minitest::Test
        def test_fails = assert_equal(1, 2)
      end
    RUBY

    refute status.success?, output
    assert_match(/Failures: 1/, output)
    assert_match(/Tests FAILED/, output)
  end

  def test_exits_non_zero_when_a_test_file_crashes
    output, status = run_bin_test_with_probe(%(raise "boom"\n))

    refute status.success?, output
    assert_match(/Errors: 1/, output)
  end

  def test_exits_zero_when_tests_pass
    output, status = run_bin_test_with_probe(<<~RUBY)
      require "minitest/autorun"
      class PassingProbe < Minitest::Test
        def test_passes = assert(true)
      end
    RUBY

    assert status.success?, output
    assert_match(/All tests PASSED/, output)
  end
end
