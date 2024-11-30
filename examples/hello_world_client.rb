#!/usr/bin/env ruby
# examples/hello_world_client.rb

require 'json'
require 'json_schema'
require 'securerandom'
require_relative '../lib/ai_agent'

class HelloWorldClient < AiAgent::Base

  def run
    super
    send_request
  end

  def send_request
    # Discover agents that can handle the 'greeting' capability
    to_uuid = discover_agent('greeting') # Pass the capability we are looking for

    request = {
      header: {
        type: 'request',
        from_uuid: id,
        to_uuid: to_uuid, # Use the discovered UUID
        event_uuid: SecureRandom.uuid,
        timestamp: Time.now.to_i
      },
      greeting: 'Hey',
      name: 'MadBomber'
    }.to_json

    send_request(request)
    logger.info "Sent request: #{request.inspect}"
  end

  def receive_response(response)
    logger.info "Received response: #{response.inspect}"
    withdraw
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
    'greeter hello_world_client'
  end
end

# Example usage
client = HelloWorldClient.new
client.run