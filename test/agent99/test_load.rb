# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"

# Regression test for issue #3: the library must load with only its
# runtime dependencies, the way it does after `gem install agent99`.
class TestLoad < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  def test_require_succeeds_without_development_dependencies
    output, status = Open3.capture2e(
      { "BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"), "BUNDLE_WITHOUT" => "development" },
      RbConfig.ruby, "-rbundler/setup", "-I", File.join(ROOT, "lib"),
      "-e", 'require "agent99"',
      chdir: ROOT
    )

    assert status.success?, "require \"agent99\" failed without development dependencies:\n#{output}"
  end
end
