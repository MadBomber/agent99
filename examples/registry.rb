#!/usr/bin/env ruby
# examples/registry.rb

require 'debug_me'
include DebugMe

require 'sinatra'
require 'json'
require 'securerandom'

# In-memory registry to store agent Array(Hash)
#
# Agent capabilities are save as lower case.  The 
# discovery process also compares content as lower case.
#
# TODO: change this data store to a sqlite database
#       maybe with a vector search capability.
#
AGENT_REGISTRY = []

# Health check endpoint
get '/healthcheck' do
  content_type :json
  { agent_count: AGENT_REGISTRY.size }.to_json
end

# Endpoint to register an agent
post '/register' do
  request.body.rewind
  request_data  = JSON.parse(request.body.read, symbolize_names: true)
  agent_name    = request_data[:name]
  agent_uuid    = SecureRandom.uuid
  
  # Ensure capabilities are lowercase
  request_data[:info][:capabilities].map!{|c| c.downcase}
  
  AGENT_REGISTRY << request_data.merge({uuid: agent_uuid})

  status 201
  content_type :json
  { uuid: agent_uuid }.to_json
end

# Endpoint to discover agents by capability
# TODO: This is a simple keyword matcher.  Looking
# =>    for a semantic match process.
get '/discover' do
  capability = params['capability'].downcase

  matching_agents = AGENT_REGISTRY.select do |agent|
    agent.dig(:info, :capabilities)&.include?(capability)
  end

  content_type :json
  matching_agents.to_json 
end

# Withdraw an agent from the registry
delete '/withdraw/:uuid' do
  uuid      = params['uuid']
  how_many  = AGENT_REGISTRY.size

  AGENT_REGISTRY.delete_if { |agent_info| agent_info[:uuid] == uuid }

  if AGENT_REGISTRY.size == how_many
    status 404 # Not Found
    content_type :json
    { error: "Agent with UUID #{uuid} not found." }.to_json
  else
    status 204 # No Content
  end
end

# Display all registered agents
get '/' do
  content_type :json
  AGENT_REGISTRY.to_json
end

# Start the Sinatra server
if __FILE__ == $PROGRAM_NAME
  Sinatra::Application.run!
end
