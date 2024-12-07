#!/usr/bin/env bash
# examples/start_rabbitmq_and_registry.sh
#
# brew install rabbitmq-server
#
# Start up the AMQP message broker (RabbitM@) in the background

echo "Starting rabbitmq-server in background ..."
rabbitmq-server &
sleep 2
open http://localhost:15672/#/queues

echo
echo
echo "Starting example registry in forground ..."
echo "http://localhost:4567"
echo
ruby registry.rb  # blocks until control-C

# You may have to do control-c twice to stop both

echo "#"
echo "##"
echo "###"
echo "####"
echo "#####"
echo "registry is stopped"
echo "stopping the rabbitmq server ...."
rabbitmqctl stop
