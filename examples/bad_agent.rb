#!/usr/bin/env ruby
# examples/bad_agent.rb
#
# This agent is meant to cause errors.

require_relative '../lib/agent99'

class BadAgent < Agent99::Base
  # this information is made available when the agent
  # registers with the central registry service.  It is
  # made available during the discovery process.
  #
  def info
    {
      name:             self.class.to_s,
      type:             :server,
      kapabilities:     %w[ rubber_stamp yes_man example ],
      # request_schema:   {}, # ExampleRequest.schema,
      # response_schema:  {}, # Agent99::RESPONSE.schema
      # control_schema:   {}, # Agent99::CONTROL.schema
      # error_schema:     {}, # Agent99::ERROR.schema
    }
  end  

  
  def receive_request
    logger.info "Example agent received request: #{payload}"
    send_response(status: 'success')
  end
end

BadAgent.new.run
