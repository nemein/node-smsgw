Hook = require('hook.io').Hook

class SenderHook extends Hook
  constructor: (@options) ->
    super @options
  
  sendMessage: (data) ->
    console.log 'sending message'
    console.log '  receiver:',data.receiver
    console.log '  content:',data.content
    
    @on "*::smsgw_outgoing_results", (results) ->
      console.log 'emitted results',results
    @on "*::smsgw_outgoing_errors", (errors) ->
      console.log 'emitted errors',errors
    
    @emit "smsgw::outgoing::#{@options.service}", data, (err, results) ->
      console.log 'callback response'
      if err
        console.log 'got error',err
        return
      console.log 'got results',results
    

sender = new SenderHook
  name: 'test-sender'
  service: 'labyrintti'
  debug: true

sender.on 'hook::ready', ->
  sender.sendMessage {receiver: '+3581234567', content: 'Hello, World!'}

sender.start()
