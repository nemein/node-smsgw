###
Copyright 2011 Jerry Jalava <jerry.jalava@nemein.com>
 
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
 
        http://www.apache.org/licenses/LICENSE-2.0
 
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
###

Hook = require('hook.io').Hook
http = require('http')
util = require('util')
_ = require('underscore')._

class OutgoingHook extends Hook
  spawned: {}
  
  constructor: (options) ->
    super options
    @port ?= 9001
    @on 'hook::ready', @_bindHooks()
  
  _bindHooks: ->    
    _.each @implementations, (config, name) =>
      @on "*::smsgw::outgoing::#{name}", @_handleRequest
  
  _handleRequest: (data, cb) ->  
    imp_name = @_determineImplementation @event
    console.log 'resolved to implementation',imp_name
    return unless imp_name
  
    @_spawnImplementation imp_name, =>
      hook_name = "smsgw_send_message"
      if Array.isArray data
        hook_name = "smsgw_send_messages"

      @emit hook_name, data, (err, result) =>        
        if err
          return @emit "smsgw_outgoing_errors", err
        @emit "smsgw_outgoing_results", result
        cb err, result
    
    @log @name, 'Outgoing SMS server started', @port
  
  _determineImplementation: (event_name) ->    
    #console.log '_determineImplementation from ',event_name
    imp_name = event_name.replace(/.*(\:\:)/, '')
    
    imp_name
      
  _spawnImplementation: (name, next) ->
    console.log 'spawn',name
    console.log @implementations
    
    if @spawned[name]
      return next()
    
    spawn_data = _.extend {type: "smsgw.#{name}", name: name, debug: @debug}, @implementations[name].config
    
    @on "children::ready", =>
      next()
    
    @spawn [spawn_data], =>
      @spawned[name] = true

exports.OutgoingHook = OutgoingHook
