# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"

# Issue #70: examples/maxwell_request.rb must load on its own, not only
# after maxwell_agent86.rb has loaded the library.
class TestMaxwellRequest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  def test_loads_on_its_own
    output, status = Open3.capture2e(
      RbConfig.ruby, "-e",
      'require_relative "examples/maxwell_request"; MaxwellRequest.schema',
      chdir: ROOT
    )

    assert status.success?, "loading examples/maxwell_request.rb failed:\n#{output}"
  end
end
