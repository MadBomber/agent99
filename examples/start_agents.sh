#!/bin/bash

# Start the registry server
echo "Starting registry server..."
# Assuming the registry server is a separate process, replace with actual command
# e.g., ruby registry_server.rb &
registry_server_command &

# Start the HelloWorld agent
echo "Starting HelloWorld agent..."
ruby examples/hello_world.rb &

# Start the HelloWorldClient agent
echo "Starting HelloWorldClient agent..."
ruby examples/hello_world_client.rb &

# Wait for all background processes to finish
wait
