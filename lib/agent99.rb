# ./lib/agent99.rb

require 'debug_me'
include DebugMe

require 'json'
require 'json_schema'
require 'securerandom'

module Agent99; end  # Establish a namespace

require_relative 'agent99/base'

module Agent99
  module Type
    SERVER = :server  # Waits for and responds to requests
    CLIENT = :client  # Only makes requests
    HYBRID = :hybrid  # Can both make and respond to requests
  end


  # TODO: anything needed here?
end
