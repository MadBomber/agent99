#!/usr/bin/env ruby
# examples/chief_agent.rb

require 'json'
require 'json_schema'
require 'securerandom'
require_relative '../lib/agent99'

class ChiefAgent < Agent99::Base
  def init
    send_request
  end

  def send_request
    to_uuid = discover_agent(capability: 'greeter', how_many: 1).first[:uuid]

    request = build_request(
                to_uuid:,
                greeting: 'Hey',
                name:     'MadBomber'
              )

    result = @message_client.publish(request)
    logger.info "Sent request: #{request.inspect}; status? #{result.inspect}"
  end

  def build_request(
                to_uuid:,
                greeting: 'Hello',
                name:     'World'
              )

    {
      header: {
        type:       'request',
        from_uuid:  @id,
        to_uuid:,
        event_uuid: SecureRandom.uuid,
        timestamp:  Agent99::Timestamp.new.to_i
      },
      greeting:,
      name:
    }
  end


  def receive_response
    logger.info "Received response: #{payload.inspect}"
    result = payload[:result]

    puts
    puts `echo "#{result}" | boxes -d info`
    puts

    exit(0)
  end

  #####################################################
  private

  def capabilities
    ['Chief of Control']
  end
end


# Example usage
client = ChiefAgent.new
client.run

