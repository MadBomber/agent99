#!/usr/bin/env ruby
# examples/registry_sqlite3.rb

require 'debug_me'
include DebugMe

require 'sinatra'
require 'json'
require 'securerandom'
require 'sqlite3'

# Initialize SQLite3 database
DB = SQLite3::Database.new('agent_registry.db')
DB.results_as_hash = true

# Create agents table if it doesn't exist
DB.execute <<-SQL
  CREATE TABLE IF NOT EXISTS agents (
    uuid TEXT PRIMARY KEY,
    info TEXT
  )
SQL

# Health check endpoint
get '/healthcheck' do
  agent_count = DB.get_first_value("SELECT COUNT(*) FROM agents")
  content_type :json
  { agent_count: }.to_json
end

# Endpoint to register an agent
post '/register' do
  request.body.rewind
  request_data = JSON.parse(request.body.read, symbolize_names: true)
  agent_uuid   = SecureRandom.uuid
  info         = request_data.to_json

  DB.execute(
    "INSERT INTO agents (uuid, info) VALUES (?, ?)",
    [agent_uuid, info]
  )

  status 201
  content_type :json
  { uuid: agent_uuid }.to_json
end

# Endpoint to discover agents by capability
get '/discover' do
  capability = params['capability'].downcase

  matching_agents = DB.execute(
    "SELECT * FROM agents WHERE json_extract(info, '$.capabilities') LIKE ?",
    ["%#{capability}%"]
  )

  content_type :json
  matching_agents.map do |agent|
    info = JSON.parse(agent['info'], symbolize_names: true)
    {
      uuid:         agent['uuid'],
      name:         info[:name],
      capabilities: info[:capabilities]
    }
  end.to_json
end

# Withdraw an agent from the registry
delete '/withdraw/:uuid' do
  uuid     = params['uuid']
  result   = DB.execute("DELETE FROM agents WHERE uuid = ?", [uuid])
  affected = DB.changes

  if affected.zero?
    status 404 # Not Found
    content_type :json
    { error: "Agent with UUID #{uuid} not found." }.to_json
  else
    status 204 # No Content
  end
end

# Display all registered agents
get '/' do
  agents = DB.execute("SELECT * FROM agents")
  content_type :json
  agents.map do |agent|
    info = JSON.parse(agent['info'], symbolize_names: true)
    {
      uuid:         agent['uuid'],
      name:         info[:name],
      capabilities: info[:capabilities]
    }
  end.to_json
end

# Cleanup method to clear the database
def cleanup_database
  DB.execute("DELETE FROM agents")
end

# Register cleanup method to be called on exit
at_exit do
  cleanup_database
end

# Start the Sinatra server
if __FILE__ == $PROGRAM_NAME
  Sinatra::Application.run!
end


