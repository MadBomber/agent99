#!/bin/bash

# Start the registry server
echo "Starting registry server..."
# Assuming the registry server is a separate process, replace with actual command
# e.g., ruby registry_server.rb &
# Replace 'registry_server_command' with the actual command to start your registry server
# Example: ruby registry_server.rb &
./registry.rb &

# Start the HelloWorld agent
echo "Starting HelloWorld agent..."
./hello_world.rb &

# Start the HelloWorldClient agent
echo "Starting HelloWorldClient agent..."
./hello_world_client.rb &

# Wait for all background processes to finish
wait
