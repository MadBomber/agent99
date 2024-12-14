#!/usr/bin/env ruby
# examples/maxwell_agent86.rb

# There are three types of agents: Server, Client and Hybrid.
# A Server receives a requests and _may_ send a response.
# A Client sends a request and _may_ expect a response.
# A Hybrid _may_ act like a Server or a Client

require_relative '../lib/agent99'
require_relative 'maxwell_request'

class MaxwellAgent86 < Agent99::Base
  REQUEST_SCHEMA  = MaxwellRequest.schema
  TYPE            = :server

  # RESPONSE_SCHEMA = Agent99::RESPONSE.schema
  # ERROR_SCHEMA    = Agent99::ERROR.schema


  #######################################
  private

  # The request is in @payload
  def receive_request
    send_response( validate_request || process )
  end


  # This method validates the incoming request and returns any errors found
  # or nil if there are no errors.
  # It allows for returning an array of errors.
  #
  # TODO: consider a 4th message type of error
  #
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
  # All response message have the same schema in that
  # they have a header (all messages have headers) and
  # a result element that is a String.  Could it be
  # a JSON string, sure but then we would need a 
  # RESPONSE_SCHEMA constant for the class.
  def process
    result  = if 50 <= rand(100)
                get(:greeting) + ' ' + get(:name)
              else
                'Missed it by that >< much.'
              end

    { result: result }
  end


  # As a server type, HelloWorld should never receive
  # a response message.
  def receive_response(response)
    loger.warn("Unexpected response type message: response.inspect")
  end


  # Phase One Implementation is to do a search
  # using the String#include? and the Array#include?
  # methods.  If you want discrete word-based selection
  # then use an Array of Strings to define the different
  # things this agent can do.
  #
  # If you want to match on sub-strings then define the
  # the capabilities as a String.
  #
  # Subsequent implementations may use a semantic search
  # to find the agents to use in which case capabilities may
  # be constrained to be a String.
  #
  # For now, lets just go with the Array of Strings.
  #
  def capabilities
    {
      info: {
        capabilities: %w[ greeter hello_world hello-world hello]
      }
    }
  end
end

# Example usage
agent = MaxwellAgent86.new
agent.run # Starts listening for messages
