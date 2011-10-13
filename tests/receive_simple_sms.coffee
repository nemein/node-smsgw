Hook = require('hook.io').Hook
request = require 'request'
querystring = require 'querystring'

INCOMING_SERVER_PORT = 9000
TEST_SENDER = "1234567890"

fakeIncoming = () ->  
  request 
    uri: "http://localhost:#{INCOMING_SERVER_PORT}/labyrintti"
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