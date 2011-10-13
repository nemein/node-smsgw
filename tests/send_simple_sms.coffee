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
