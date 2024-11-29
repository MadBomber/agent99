# examples/hello_world.rb

require 'json'
require 'json_schema'

require_relative '../lib/ai_agent'
require_relative 'hello_world_request'

class HelloWorld < AiAgent::Base
  REQUEST_SCHEMA = HelloWorldRequest.schema

  # The request is in @payload
  def receive_request
    send_response( validate_request || process )
  end

  # This method validates the incoming request and returns any errors found
  # or nil if there are no errors.
  # It allows for returning an array of errors.
  def validate_request
    responses = []

    # Check if the ID matches
    unless id == to_uuid
      logger.error <<~ERROR
        #{name} received someone else's request
        id: #{id}  timestamp: #{timestamp}
        to_uuid:   #{to_uuid}
        from_uuid: #{from_uuid}
        event_uuid:#{event_uuid}
      ERROR
      responses << {
        error: "Incorrect message queue for header",
        details: {
          id:     id,
          header: header
        }
      }
    end

    # Validate the incoming request body against the schema
    validation_errors = validate_schema
    unless validation_errors.empty?
      logger.error "Validation errors: #{validation_errors}"
      responses << {
        error:    "Invalid request", 
        details:  validation_errors
      }
    end

    responses.empty? ? nil : responses
  end

  # Returns the response value
  def process
    {
      event_uuid: event_uuid,
      result: get(:greeting) + ' ' + get(:name)
    }
  end


  def receive_response(response)
    # Handle the response here (currently a no-op)
    nil
  end

  private

  # NOTE: what I'm thinking about here is similar to the
  #       prompt tool (aka function) callback facility
  #       where descriptive text is used to describe
  #       what the tool does.
  def capabilities
    <<~STRING.chomp
      Create a salutation.  For example "Hello World"
      or "Hi Johnny" using two parameters :greeting and :name
    STRING    
  end

  # TODO: Move to Base class
  def default(field)
    REQUEST_SCHEMA.dig(:properties, field, :examples)&.first
  end

  def get(field)
    payload[field] || default(field)
  end
end

# Example usage
agent = HelloWorld.new(name: "hello_world")
agent.run # Starts listening for messages
