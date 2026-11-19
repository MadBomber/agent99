# frozen_string_literal: true

require "minitest/autorun"
require "open3"

class TestGemspec < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  SHIPPED_DIRS = %w[lib/ sig/ examples/].freeze
  SHIPPED_ROOT_FILES = %w[README.md CHANGELOG.md LICENSE].freeze

  # Skip the mock registry server test_helper starts for every test.
  # spec.files intersects with `git ls-files`, so outside a git checkout
  # (git archive, Download ZIP, release tarball) it is empty by design.
  def setup
    _out, _err, status = Open3.capture3("git", "rev-parse", "--is-inside-work-tree", chdir: ROOT)
    skip "#{ROOT} is not a git work tree; spec.files relies on git ls-files" unless status.success?
  rescue SystemCallError
    skip "git is not available; spec.files relies on git ls-files"
  end

  def teardown; end

  def spec_files
    @spec_files ||= Gem::Specification.load(File.join(ROOT, "agent99.gemspec")).files
  end

  def test_ships_every_lib_file
    lib_files = Dir.glob("lib/**/*", base: ROOT).reject { |f| File.directory?(File.join(ROOT, f)) }

    assert_empty lib_files - spec_files
  end

  def test_ships_readme_changelog_and_license
    assert_empty SHIPPED_ROOT_FILES - spec_files
  end

  def test_ships_type_signatures
    assert_includes spec_files, "sig/ai_agent.rbs"
  end

  def test_ships_examples_because_they_are_on_the_load_path
    assert_includes spec_files, "examples/example_agent.rb"
  end

  def test_ships_nothing_outside_the_allowlist
    stray = spec_files.reject do |f|
      f.start_with?(*SHIPPED_DIRS) || SHIPPED_ROOT_FILES.include?(f)
    end

    assert_empty stray
  end
end
