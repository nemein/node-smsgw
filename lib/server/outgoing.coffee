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

messages = require '../messages'

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
    #console.log 'resolved to implementation',imp_name
    return unless imp_name
  
    @_spawnImplementation imp_name, =>
      hook_name = "smsgw_send_message"      
      if Array.isArray data
        hook_name = "smsgw_send_messages"
      #console.log 'hook_name',hook_name
      @emit hook_name, @_convertToMessages(imp_name, data), (err, result) =>
        if err
          @emit "smsgw_outgoing_errors", err
        else
          @emit "smsgw_outgoing_results", result
        cb err, result
    
    @log @name, 'Outgoing SMS server started', @port
  
  _convertToMessages: (imp_name, datas) ->
    unless Array.isArray datas
      return @_convertToMessage imp_name, datas
    messages = []
    _.each datas, (data) ->
      messages.push @_convertToMessage imp_name, data
      
    return messages
  
  _convertToMessage: (imp_name, data) ->
    message_class = messages.SMS
    if data.type and data.type.toLowerCase() == 'mms'
      message_class = messages.MMS
    
    message = new messages.SMS(data.receiver, data.content)
    message.parser = imp_name
    
    if data.message_class and _.include message_class.AVAILABLE_CLASSES, data.message_class
      message.msg_class = data.message_class
        
    message.setSender data.sender if data.sender
    
    message = messages.serialize message
    
    return message    
  
  _determineImplementation: (event_name) ->    
    #console.log '_determineImplementation from ',event_name
    imp_name = event_name.replace(/.*(\:\:)/, '')
    
    imp_name
      
  _spawnImplementation: (name, next) ->
    #console.log '_spawnImplementation',name
    #console.log @spawned[name]
    if @spawned[name]
      if @spawned[name] > 1
        return next()
      else
        @on "children::ready", =>
          #console.log 'children::ready 1'
          next()
        return
    
    spawn_data = _.extend {type: "smsgw.#{name}", name: name, debug: @debug}, @implementations[name].config
    
    @on "children::ready", =>
      #console.log 'children::ready 2'
      next()
    
    @spawned[name] = 1
    @spawn [spawn_data], =>
      @spawned[name] = 2

exports.OutgoingHook = OutgoingHook
