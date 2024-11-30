# ./lib/ai_agent.rb

require 'debug_me'
include DebugMe

module AiAgent; end  # Establish a namespace

require_relative 'ai_agent/base'

module AiAgent
  module Type
    SERVER = :server  # Waits for and responds to requests
    CLIENT = :client  # Only makes requests
    HYBRID = :hybrid  # Can both make and respond to requests
  end


  # TODO: anything needed here?
end
