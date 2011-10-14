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

class IncomingHook extends Hook
  spawned: {}
  
  constructor: (options) ->
    super options
    @port ?= 9000
    @on 'hook::ready', @_startServer()
  
  _startServer: ->
    http.createServer (req, res) =>
      body = ''
      
      unless req.url.match(/^\/incoming/) or req.url.match(/^\/report/)
        #console.log 'url not starting with /incoming or /report'
        return
      
      # Buffer up all the body data from incoming request
      req.on 'data', (data) ->
        body += data
      
      # On the end of the request, emit a hook.io message with SMSMessage payload
      req.on 'end', () =>
        
        imp_name = @_determineImplementation req
        #console.log 'resolved to implementation',imp_name
        return unless imp_name
        
        @_spawnImplementation imp_name, =>
          hook_name = "smsgw_parse_messages"
          response_hook_name = "smsgw_incoming"
          if req.url.match(/^\/report/)
            hook_name = "smsgw_parse_reports"
            response_hook_name = "smsgw_incoming_report"
          
          @emit hook_name,
            url: req.url
            body: body
          , (err, result) =>
            if result.headers
              _.each result.headers, (opts, code) ->
                res.writeHead code, opts
            if result.body
              res.end result.body
            else
              res.end()
            
            if result.message
              result.message = messages.unserialize result.message
              
              @emit response_hook_name, result.message
              if result.message.keywords and result.message.keywords.length
                keywords = result.message.keywords.join("|").toLowerCase()
                @emit "#{response_hook_name}.#{keywords}", result.message
                
    .listen @port
    
    @log @name, 'Incoming SMS server started', @port
    @log @name, 'Handling messages at /incoming and delivery reports at /reports'
  
  _determineImplementation: (req) ->    
    imp_name = null
    
    url = req.url
    if url and (url.replace('/incoming', '').length > 1 or url.replace('/report', '').length > 1)
      # Determine from url
      _.each @implementations, (config, name) =>
        if url.match(new RegExp(name, "gi"))
          imp_name = name
    
    return imp_name if imp_name
    
    if req.headers.referer
      # Determine from referer
      _.each @implementations, (config, name) ->
        if config.referer
          if req.headers.referer.match(new RegExp(config.referer, "gi"))
            imp_name = name
        
    imp_name
      
  _spawnImplementation: (name, next) ->
    if @spawned[name]
      return next()
    
    spawn_data = _.extend {type: "smsgw.#{name}", name: name, debug: @debug}, @implementations[name].config
    
    @on "children::ready", =>
      next()
    
    @spawn [spawn_data], =>
      @spawned[name] = true

exports.IncomingHook = IncomingHook
