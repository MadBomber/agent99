#!/usr/bin/env ruby
# examples/hello_world_client.rb

require 'json'
require 'json_schema'
require 'securerandom'
require_relative '../lib/ai_agent'

class HelloWorldClient < AiAgent::Base
  def init
    send_request
  end

  def send_request
    # Discover agents that can handle the 'greeter' capability
    to_uuid = discover_agent('greeter') # Pass the capability we are looking for

    request = {
      header: {
        type:       'request',
        from_uuid:  @id,
        to_uuid:    to_uuid,
        event_uuid: SecureRandom.uuid,
        timestamp:  Time.now.to_i
      },
      greeting: 'Hey',
      name: 'MadBomber'
    }

    @message_client.publish(to_uuid, request)
    logger.info "Sent request: #{request.inspect}"
  end

  def receive_response
    logger.info "Received response: #{@payload.inspect}"
    exit(0)
  end

  private

  def discover_agent(capability)
    result = @registry_client.discover(capability: capability)

    if result.empty?
      logger.error "No agents found for capability: #{capability}"
      raise "No agents available"
    end

    # Assuming that the registry returns a hash of { uuid: agent_name }
    result.keys.first # Return the first UUID found
  end

  def capabilities
    ['hello_world_client']
  end
end


# Example usage
client = HelloWorldClient.new
client.run

