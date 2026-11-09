# frozen_string_literal: true

require "minitest/autorun"
require "open3"

# Regression test for issue #3: the library must load with only its
# runtime dependencies, the way it does after `gem install agent99`.
class TestLoad < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  # BUNDLE_ONLY wins over any `with`/`without` setting in env or .bundle/config.
  CHILD_ENV = {
    "BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"),
    "BUNDLE_ONLY" => "default",
    "RUBYOPT" => nil,
    "RUBYLIB" => nil
  }.freeze

  # Skip the shared mock registry server from test_helper; the check runs in a child process.
  def setup; end
  def teardown; end

  def test_require_succeeds_with_runtime_dependencies_only
    output, status = Open3.capture2e(
      CHILD_ENV,
      RbConfig.ruby, "-rbundler/setup", "-I", File.join(ROOT, "lib"),
      "-e", 'require "agent99"; abort "DebugMe is mixed into Object" if defined?(DebugMe)',
      chdir: ROOT
    )

    assert status.success?, "child process failed loading agent99 with BUNDLE_ONLY=default:\n#{output}"
  end
end
