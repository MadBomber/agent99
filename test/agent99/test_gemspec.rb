# frozen_string_literal: true

require "minitest/autorun"

class TestGemspec < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)
  SHIPPED_DIRS = %w[lib/ sig/ examples/].freeze
  SHIPPED_ROOT_FILES = %w[README.md CHANGELOG.md LICENSE].freeze

  def spec_files
    @spec_files ||= Gem::Specification.load(File.join(ROOT, "agent99.gemspec")).files
  end

  def test_ships_every_lib_ruby_file
    lib_files = Dir.glob("lib/**/*.rb", base: ROOT)

    assert_empty lib_files - spec_files
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
