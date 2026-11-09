# frozen_string_literal: true

require "minitest/autorun"
require "open3"

# Regression test for issue #3: the library must load with only its
# runtime dependencies, the way it does after `gem install agent99`.
class TestLoad < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  # Skip the shared mock registry server from test_helper; the check runs in a child process.
  def setup; end
  def teardown; end

  def test_require_succeeds_without_development_dependencies
    output, status = Open3.capture2e(
      {
        "BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"),
        "BUNDLE_WITHOUT" => "development",
        "BUNDLE_WITH" => nil, "RUBYOPT" => nil, "RUBYLIB" => nil
      },
      RbConfig.ruby, "-rbundler/setup", "-I", File.join(ROOT, "lib"),
      "-e", 'require "agent99"',
      chdir: ROOT
    )

    assert status.success?, "child process failed loading agent99 with BUNDLE_WITHOUT=development:\n#{output}"
  end
end
