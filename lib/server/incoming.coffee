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
  parsers: {}
  
  constructor: (options) ->
    super options
    @port ?= 9000
    @on 'hook::ready', @_startServer()
  
  _startServer: ->
    @_loadParsers()
    
    http.createServer (req, res) =>
      body = ''
      
      # Buffer up all the body data from incoming request
      req.on 'data', (data) ->
        body += data
      
      # On the end of the request, emit a hook.io message with SMSMessage payload
      req.on 'end', () =>
        
        parser_name = @_determineParser req
        console.log 'resolved to parser',parser_name
        return unless parser_name
          
        @emit "smsgw::#{parser_name}::parse",
          url: req.url
          body: body
        , (err, response) =>
          if response.headers
            _.each response.headers, (opts, code) ->
              res.writeHead code, opts
          if response.body
            res.end response.body
          else
            res.end()
          
          if response.message
            @emit 'smsgw::incoming', response.message
    .listen @port
    
    @log @name, 'Incoming SMS server started', @port
  
  _determineParser: (req) ->    
    parser = null
    
    if req.url and req.url.length > 1
      # Determine from url
      _.each @implementations, (config, name) =>
        if req.url.match(new RegExp(name, "gi"))
          parser = name
    
    return parser if parser
    
    if req.headers.referer
      # Determine from referer
      _.each @implementations, (config, name) ->
        if config.referer
          if req.headers.referer.match(new RegExp(config.referer, "gi"))
            parser = name
        
    parser
  
  _loadParsers: ->
    _.each @implementations, (opts, name) =>
      @_startParser name
      
  _startParser: (name)->
    if @parsers[name]
      return
    
    # TODO: Split implementations to own modules, so we can just spawn them
    
    opts = @implementations[name]
    config = _.extend {name: "#{name}-parser", debug: @debug}, opts.config
    parser = require("../implementations/#{name}/parser")
    @parsers[name] = new parser(config)
    @parsers[name].start()

exports.IncomingHook = IncomingHook
