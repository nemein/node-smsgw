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
querystring = require 'querystring'

messages = require '../../messages'

class ParserHook extends Hook
  constructor: (options) ->
    super options
    @on '*::smsgw::labyrintti::parse', @_parse
  
  _parse: (data, cb) ->
    body = querystring.parse data.body
    
    msg = new messages.SMS
    msg.setSender body.source || body.from_number
    msg.addRecipient body.dest      
    msg.operator = body.operator
    msg.keywords = body.keyword
    msg.parameters = body.params.split(" ")
    if body.header
      msg.header = body.header
    if body.text
      msg.setText body.text
    if body.binary
      msg.setBinary body.binary
    
    cb null,
      headers: [
        200: {'content-type': 'text/plain'}
      ]
      body: 'OK'
      message: msg
    

exports = module.exports = ParserHook
