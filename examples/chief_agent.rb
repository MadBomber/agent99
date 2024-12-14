#!/usr/bin/env ruby
# examples/chief_agent.rb
#
# This program is a type :client agent.
#
# This program calls a CLI program named boxes to highlight
# the response received to the request that it sent.
#
# brew install boxes
#
# Run this program several times to see if Maxwell Agent86
# messes up his mission which he is prone to do half the time.

require_relative '../lib/agent99'

class ChiefAgent < Agent99::Base
  # this information is made available when the agent
  # registers with the central registry service.  It is
  # made available during the discovery process.
  #
  def info
    {
      name:             self.class.to_s,
      type:             :client,
      capabilities:     ['Chief of Control'],
      # request_schema:   ChiefRequest.schema,
      # response_schema:  {}, # Agent99::RESPONSE.schema
      # control_schema:   {}, # Agent99::CONTROL.schema
      # error_schema:     {}, # Agent99::ERROR.schema
    }
  end



  # init is called at the end of the initialization process.
  # It may be only something that a :client type agent would do.
  #
  # For this client it sends out a request as its first order of
  # business and expects to receive a response.
  #
  def init
    action  = 'greeter'
    agent   = discover_agent(
                capability: action, 
                how_many:   1
              ).first[:uuid]

    send_request(agent:)

  rescue Exception => e
    logger.warn "No Agents are available as #{action}"
    exit(1)
  end


  ##################################################
  private

  def send_request(agent:)
    request = build_request(
                to_uuid:  agent,
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
        to_uuid:    ,
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
end


# Example usage
client = ChiefAgent.new
client.run

