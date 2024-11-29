require 'json'
require 'json_schema'

require_relative '../lib/ai_agent/registry_client'
require_relative '../lib/ai_agent/message_client'

class HelloWorldClient < AiAgent::Base
  def initialize(
      registry_client:  RegistryClient.new, 
      message_client:   MessageClient.new,
      logger:           Logger.new($stdout)
    )
    super
    @name = "hello_world_client"
  end

  def run
    super
    send_request
  end

  def send_request
    request = {
      type: 'request',
      header: {
        from_uuid: id,
        to_uuid: 'hello_world', # Assuming the HelloWorld agent is registered with this ID
        event_uuid: SecureRandom.uuid,
        timestamp: Time.now.to_i
      },
      greeting: 'Hello',
      name: 'World'
    }
    message_client.channel.default_exchange.publish(
      request.to_json,
      routing_key: @queue.name
    )
    logger.info "Sent request: #{request.inspect}"
  end

  def receive_response(response)
    logger.info "Received response: #{response.inspect}"
    withdraw
  end

  private

  def capabilities
    "Send a greeting request to HelloWorld agent and print the response."
  end
end

# Example usage
client = HelloWorldClient.new
client.run
