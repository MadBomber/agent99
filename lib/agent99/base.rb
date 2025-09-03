# lib/agent99/base.rb

require 'logger'
require 'json'
require 'simple_json_schema_builder'

require_relative 'timestamp'
require_relative 'registry_client'
require_relative 'amqp_message_client'
require_relative 'nats_message_client'

require_relative 'header_management'
require_relative 'agent_discovery'
require_relative 'control_actions'
require_relative 'agent_lifecycle'
require_relative 'message_processing'

# The Agent99::Base class serves as the foundation for creating AI agents in a distributed system.
# It provides core functionality for agent registration, message handling, and communication.
#
# This class:
# - Manages agent registration and withdrawal
# - Handles incoming messages (requests, responses, and control messages)
# - Provides a framework for defining agent capabilities
# - Implements error handling and logging
# - Supports configuration updates and status reporting
#
# Subclasses should override specific methods like `receive_request`, `receive_response`,
# and `capabilities` to define custom behavior for different types of agents.
#
class Agent99::Base
  include Agent99::HeaderManagement
  include Agent99::AgentDiscovery
  include Agent99::ControlActions
  include Agent99::AgentLifecycle
  include Agent99::MessageProcessing

  MESSAGE_TYPES = %w[request response control]

  attr_reader :id, :capabilities, :name
  attr_reader :payload, :header, :queue
  attr_reader :logger
  attr_reader :agents
  
  attr_accessor :registry_client, :message_client


  ###################################################
  private

  def handle_error(message, error)
    logger.error "#{message}: #{error.message}"
    logger.debug error.backtrace.join("\n")
  end


  # the final rescue block
  rescue StandardError => e
    handle_error("Unhandled error in Agent99::Base", e)
    exit(2)
end


