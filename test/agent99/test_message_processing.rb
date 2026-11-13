# frozen_string_literal: true

require "test_helper"

class TestMessageProcessing < Minitest::Test
  def build_agent(klass, payload)
    agent = klass.allocate
    agent.instance_variable_set(:@payload, payload)
    agent
  end

  def test_get_returns_nil_for_missing_field_without_request_schema
    klass = Class.new(Agent99::Base)
    agent = build_agent(klass, { name: "World" })

    assert_equal "World", agent.send(:get, :name)
    assert_nil agent.send(:get, :greeting)
  end

  def test_get_falls_back_to_request_schema_example
    klass = Class.new(Agent99::Base) do
      const_set(:REQUEST_SCHEMA, { properties: { greeting: { examples: ["Hello"] } } })
    end
    agent = build_agent(klass, {})

    assert_equal "Hello", agent.send(:get, :greeting)
  end

  def test_get_uses_request_schema_inherited_from_parent_agent
    parent = Class.new(Agent99::Base) do
      const_set(:REQUEST_SCHEMA, { properties: { greeting: { examples: ["Hi"] } } })
    end
    agent = build_agent(Class.new(parent), {})

    assert_equal "Hi", agent.send(:get, :greeting)
  end
end
