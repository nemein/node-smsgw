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
request = require 'request'
querystring = require 'querystring'

INCOMING_SERVER_PORT = 9000
TEST_SENDER = "1234567890"

fakeIncoming = () ->  
  request 
    uri: "http://localhost:#{INCOMING_SERVER_PORT}/incoming/labyrintti"
    method: "POST"
    headers:
      'Referer': 'gw.labyrintti.com:28080'
      'Content-Type': 'application/x-www-form-urlencoded'
    body: querystring.stringify
      source: TEST_SENDER
      operator: "nodejs"
      dest: "12345"
      keyword: "SMSGW_TEST"
      params: "sample message"
      text: "test sample message"
    , (err, res, body) ->
      if err
        throw err
      console.log 'Got response headers',res.headers
      console.log 'Got response body',body

class ReceiverHook extends Hook
  constructor: (@options) ->
    super @options

receiver = new ReceiverHook
  name: 'test-receiver'
  debug: true

receiver.on 'hook::ready', ->
  @on '*::smsgw_incoming', (message) ->
    console.log 'hook received message',message
  receiver.on '*::smsgw_incoming.smsgw_test', (message) ->
    console.log 'hook received message with keyword SMSGW_TEST',message
  
  fakeIncoming()

receiver.start()