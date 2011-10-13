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
Parser = require './parser'
Sender = require './sender'

class MainHook extends Hook
  constructor: (@options) ->
    super @options
    
    @parser = new Parser(@options)
    @sender = new Sender(@options)
    
    @on '*::smsgw_parse_messages', @_parseMessages
    @on '*::smsgw_parse_reports', @_parseReports    
    @on '*::smsgw_send_messages', @_sendMessages
    @on '*::smsgw_send_message', @_sendMessage
  
  _parseMessages: (data, cb) ->
    @parser.parse data, cb
    
  _parseReports: (data, cb) ->
    @parser.parseReport data, cb
  
  _sendMessages: (data, cb) ->
    message_count = data.length
    sent_messages = 0
    results = []
    
    next = (err, res) ->
      sent_messages += 1
      if err
        results.push err
      else
        results.push res
      if sent_messages == message_count
        cb null, results
    
    _.each data, (msg) =>
      @_sendMessage msg, next
  
  _sendMessage: (msg, cb) ->
    @sender.send msg, cb
    
exports.MainHook = MainHook
