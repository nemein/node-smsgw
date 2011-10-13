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

querystring = require 'querystring'

messages = require('node-smsgw').Messages

class Sender
  constructor: (@options) ->
  
  send: (data, cb) ->
    console.log 'send',data
    
    msg = data.message # Instance of messages.SMS or messages.MMS
    #msg = new messages.SMS data.receiver, data.content
    
    results = null
    
    unless results
      return cb {status: 'failed'}      
    cb null, results
    
exports = module.exports = Sender
