# frozen_string_literal: true

require "minitest/autorun"
require "open3"

# Regression test for issue #3: the library must load with only its
# runtime dependencies, the way it does after `gem install agent99`.
class TestLoad < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  # BUNDLE_ONLY narrows Bundler to the runtime group whatever `with`/`without`
  # says; only an `only` key in the repo's own .bundle/config would override it.
  CHILD_ENV = {
    "BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"),
    "BUNDLE_ONLY" => "default",
    "BUNDLE_APP_CONFIG" => nil,
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
      "-e", 'require "agent99"',
      chdir: ROOT
    )

    assert status.success?, "child process failed loading agent99 with BUNDLE_ONLY=default:\n#{output}"
  end

  # Issues #15 and #21: README step 1 uses Agent99::HeaderSchema right after `require "agent99"`.
  # bundler/setup evaluates agent99.gemspec, which loads version.rb; undo that first
  # so the child sees what a plain `gem install agent99` user sees.
  def test_require_defines_version_and_header_schema
    script = <<~RUBY
      Agent99.send(:remove_const, :VERSION)
      $LOADED_FEATURES.reject! { |f| f.end_with?("/agent99/version.rb") }
      require "agent99"
      p Agent99::VERSION, Agent99::HeaderSchema.schema
    RUBY

    output, status = Open3.capture2e(
      CHILD_ENV,
      RbConfig.ruby, "-rbundler/setup", "-I", File.join(ROOT, "lib"),
      "-e", script,
      chdir: ROOT
    )

    assert status.success?, "constant missing after require \"agent99\":\n#{output}"
  end
end
