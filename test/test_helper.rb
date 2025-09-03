# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "agent99"

require "minitest/autorun"
require "logger"
require "json"
require "securerandom"

# Load test infrastructure
require_relative "support/test_infrastructure"

# Configure test environment
class Minitest::Test
  def setup
    @logger = Logger.new('/dev/null')
    @registry_server = TestInfrastructure::MockRegistryServer.new.start
    @message_client = TestInfrastructure::MockAmqpMessageClient.new
  end

  def teardown
    @registry_server&.stop
  end

  def registry_url
    "http://localhost:#{@registry_server.port}"
  end

  def create_test_agent(name:, capabilities:)
    registry_client = Agent99::RegistryClient.new(
      base_url: registry_url,
      logger: @logger
    )
    
    TestInfrastructure::TestAgent.new(
      name: name,
      capabilities: capabilities,
      registry_client: registry_client,
      message_client: @message_client,
      logger: @logger
    )
  end
end
