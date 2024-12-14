# examples/example_agent.rb
#
# NOTE: This agent is meant to be loaded
#       by the agent_watcher.rb be file.
#       To do that first have AgentWatcher running
#       then `cp example_agent.rb agents`
#       AgentWatcher will see the new file arrive
#       in the `agents` folder, will determine that the
#       new file contains an Agent99 subclass, will
#       load it, create a new instance of the class and
#       finally run the new instance within its own
#       thread as part of the AgentWatcher process.
#

require_relative '../../lib/agent99'

class ExampleAgent < Agent99::Base
  # this information is made available when the agent
  # registers with the central registry service.  It is
  # made available during the discovery process.
  #
  def info
    {
      name:             self.class.to_s,
      type:             :server,
      capabilities:     %w[ rubber_stamp yes_man example ],
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
