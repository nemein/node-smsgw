# SMS Gateway

This is SMS Gateway service built on top of Node.JS
It is extendable to support multiple different SMS services and its main usage
happens through Hook.IO hooks.

## Incoming

Server will listen on defined port for incoming HTTP requests and pass the requests to configured service implementations,
which parse the requests and convert them to SMS or Delivery report -message objects
These SMS -objects are then broadcasted to Hook.IO cloud

## Outgoing

This is Hook.IO hook which listens for incoming messages and translates them to configured service implementation
actions.

# For developer

After cloning, install using npm "npm install . --local" and to enable implementations you have to 
symlink them to node_modules -folder, so "cd node_modules && ln -s ../implementations/NAME ."

# Testing

Currently to do message parsing flow test run (inside the project dir) "./bin/incoming_server"
and then on other terminal run "coffee tests/send_simple_sms.coffee"

# Supported services

* Labyrintti (State: Alpha)

