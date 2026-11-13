# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

# Only real test files; test_helper.rb and test/support/ also match the
# default test_*.rb glob and fail if loaded before test_helper.
Minitest::TestTask.create do |t|
  t.test_globs = ["test/{agent99,integration,system}/**/test_*.rb"]
end

task default: :test

# Additional test tasks for Agent99
require "rake/testtask"

# Unit tests only
Rake::TestTask.new(:test_unit) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList["test/agent99/*test*.rb"]
  t.verbose = true
end

# Integration tests only
Rake::TestTask.new(:test_integration) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList["test/integration/*test*.rb"]
  t.verbose = true
end

# System tests only
Rake::TestTask.new(:test_system) do |t|
  t.libs << "lib"
  t.libs << "test"  
  t.test_files = FileList["test/system/*test*.rb"]
  t.verbose = true
end

desc "Show test statistics"
task :test_stats do
  unit_tests = Dir.glob("test/agent99/*test*.rb").size
  integration_tests = Dir.glob("test/integration/*test*.rb").size
  system_tests = Dir.glob("test/system/*test*.rb").size
  total_tests = unit_tests + integration_tests + system_tests
  
  puts "Test Statistics:"
  puts "  Unit tests: #{unit_tests}"
  puts "  Integration tests: #{integration_tests}"
  puts "  System tests: #{system_tests}"
  puts "  Total test files: #{total_tests}"
  
  # Count test methods
  test_methods = 0
  Dir.glob("test/**/*test*.rb").each do |file|
    content = File.read(file)
    test_methods += content.scan(/def test_/).size
  end
  
  puts "  Total test methods: #{test_methods}"
end
