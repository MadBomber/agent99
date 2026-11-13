# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../examples/run_demo"

# Issue #65: run_demo.rb writes demo agents into examples/agents/, so the
# generated require_relative must resolve from that directory.
class TestRunDemo < Minitest::Test
  def test_generated_agent_requires_the_library_from_examples_agents
    code = Agent99Demo.allocate.send(:generate_demo_agent_code, "DemoAgent2", ["demo"])
    path = code[/require_relative ['"]([^'"]+)['"]/, 1]

    refute_nil path, "generated code has no require_relative"
    target = File.expand_path(path, File.join(Agent99Demo::EXAMPLES_DIR, "agents"))
    assert File.exist?("#{target}.rb"), "require_relative '#{path}' from examples/agents/ resolves to missing #{target}.rb"
  end
end
