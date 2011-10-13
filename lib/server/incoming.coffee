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

class IncomingHook extends Hook
  spawned: {}
  
  constructor: (options) ->
    super options
    @port ?= 9000
    @on 'hook::ready', @_startServer()
  
  _startServer: ->
    http.createServer (req, res) =>
      body = ''
      
      # Buffer up all the body data from incoming request
      req.on 'data', (data) ->
        body += data
      
      # On the end of the request, emit a hook.io message with SMSMessage payload
      req.on 'end', () =>
        
        imp_name = @_determineImplementation req
        #console.log 'resolved to implementation',imp_name
        return unless imp_name
        
        @_spawnImplementation imp_name, =>
          @emit "smsgw_parse_messages",
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
              @emit 'smsgw_incoming', result.message
              if result.message.keywords.length
                keywords = result.message.keywords.join("|").toLowerCase()
                @emit "smsgw_incoming.#{keywords}", result.message
                
    .listen @port
    
    @log @name, 'Incoming SMS server started', @port
  
  _determineImplementation: (req) ->    
    imp_name = null
    
    if req.url and req.url.length > 1
      # Determine from url
      _.each @implementations, (config, name) =>
        if req.url.match(new RegExp(name, "gi"))
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
