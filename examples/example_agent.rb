# examples/example_agent.rb

require_relative '../lib/agent99'

class ExampleAgent < Agent99::Base
  TYPE = :server
  
  def capabilities = %w[ rubber_stamp yes_man example ]
  
  def receive_request
    logger.info "Example agent received request: #{payload}"
    send_response(status: 'success')
  end
end
