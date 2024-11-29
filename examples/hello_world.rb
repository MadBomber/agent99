# experiments/agents/hello_world.rb

require 'json'
require 'json_schema'

require_relative 'ai_agent'
require_relative 'hello_world_request'

class HelloWorld < AiAgent::Base
  REQUEST_SCHEMA = HelloWorldRequest.schema

  # The request is in @payload
  def receive_request
    response = validate_request || process
    send_response(response)
  end

  # FIXME: return errors in response format
  # returns nil when there are no errors
  # FIXME: allow for an Array of errors.
  #
  def validate_request
    response = nil

    # TODO: move this wrong id test into the Base class
    unless id == to_uuid
      logger.error <<~ERROR
        #{name} received someone else's request
        id: #{id}  timestamp: #{timestamp}
        to_uuid:   #{to_uuid}
        from_uuid: #{from_uuid}
        event_uuid:#{event_uuid}
      ERROR
      response = {
        error: "Incorrect message queue for header",
        details: {
          id:     id,
          header: header
        }
      }
    end

    # Validate the incoming request body against the schema
    validation_errors = validate_request(request)
    
    if validation_errors.any?
      logger.error "Validation errors: #{validation_errors}"
      response = {
        error:    "Invalid request", 
        details:  validation_errors
      }
    end

    response
  end

  # Returns the response value
  def process
    {
      event_uuid: event_uuid,
      result: "hello world"  
    }
  end


  def receive_response(response)
    nil
  end

  private

end

# Example usage
agent = HelloWorld.new(name: "hello_world", capabilities: ["world greeter", "person greeter"])
agent.run # Starts listening for AMQP messages
