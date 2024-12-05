# lib/agent99/base.rb

require 'logger'
require 'json'
require 'json_schema'

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
  
  CONTROL_HANDLERS = {
    'shutdown' => :handle_shutdown,
    'pause' => :handle_pause,
    'resume' => :handle_resume,
    'update_config' => :handle_update_config,
    'status' => :handle_status_request
  }

  attr_reader :id, :capabilities, :name, :payload, :header, :logger, :queue
  attr_accessor :registry_client, :message_client


  ###################################################
  private

  def handle_error(message, error)
    logger.error "#{message}: #{error.message}"
    logger.debug error.backtrace.join("\n")
  end
end


