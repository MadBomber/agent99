# frozen_string_literal: true

require "minitest/autorun"
require "rubygems"

class TestGemspec < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

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

  def test_leaves_out_docs_and_development_files
    unwanted = spec_files.select do |f|
      f.start_with?("docs/", "test/", "bin/", ".") ||
        f.end_with?(".db") ||
        %w[Rakefile mkdocs.yml COMMITS.md DOCS.md agent99.gemspec].include?(f) ||
        File.basename(f) == ".irbrc"
    end

    assert_empty unwanted
  end
end
