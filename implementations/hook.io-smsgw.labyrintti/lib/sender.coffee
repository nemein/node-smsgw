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

http = require 'http'
querystring = require 'querystring'
_ = require('underscore')._

messages = require('node-smsgw').Messages

class Sender
  constructor: (@options) ->
  
  send: (data, cb) ->    
    msg = messages.unserialize data
    #console.log 'msg',msg
    
    sendResponse = (err, response) ->
      #console.log 'sendResponse',err,response
      return cb err if err
      cb null, response
    
    http_options = 
      host: @_getServiceHost()
      port: @options.port
      path: @_getServicePath(msg)
      method: 'POST'
      headers:
        'content-type': 'application/x-www-form-urlencoded'
    
    process.on 'uncaughtException', (err) ->
      result =
        code: err.code
        errno: err.errno
        msg: err.message
      sendResponse result
    
    try
      req = http.request http_options, (res) =>        
        res.setEncoding 'utf8'
        body = ''
        res.on 'data', (chunk) ->
          body += chunk
        res.on 'end', () =>
          result =
            code: res.statusCode
            status: 'FAILED'
            msg: querystring.parse body
        
          if res.statusCode == 200
            result.status = 'OK'
            result = @_parseResultString msg, body, result
            sendResponse null, result
          else            
            sendResponse result
      
      req.on 'error', (err) ->
        result =
          code: err.code
          errno: err.errno
          msg: err.message
        return sendResponse result
      
      req.write @_generatePostData(msg)
      req.end()
    catch err
      result =
        code: err.code
        errno: err.errno
        msg: err.message
      return sendResponse result
  
  _parseResultString: (msg, body, result) ->
    body = decodeURIComponent body    
    lines = body.toString().split("\r\n")
    
    result.msg = body
    result.statuses = []
    _.each lines, (line) ->
      return unless line or line.length
      line_parts = line.match /^(\+[0-9]+) (\w+) (\d+) (.+)$/
      
      return unless line_parts.length
      _.each msg.recipients, (recipient) ->
        recipient = recipient.substr(1)
        if line_parts[1].match(recipient)
          rec_status = {
            number: line_parts[1]
            matched_number: recipient
            status: line_parts[2]
            code: parseInt line_parts[3]
            msg: line_parts[4]
          }
          result.statuses.push rec_status      
    result
  
  _getServiceHost: () ->
    #url = "http://"
    url = ""
    # if @options.secure
    #   url = "https://"
    url += @options.host
    
    url
  
  _getServicePath: (msg) ->
    type = msg.__proto__.constructor.name.toLowerCase()
    
    return "/sendsms" if type is "sms"
    return "/sendmms" if type is "mms"    
    "/sendsms"
  
  _generatePostData: (msg) ->
    data = 
      user: @options.api_user
      password: @options.api_password
    
    report_url = null
    if @options.report_url
      report_url = @options.report_url
    if msg.getReportUrl()
      report_url = msg.getReportUrl()
    
    if report_url
      data['report'] = @config.options.client.report_url
    
    data = _.extend data, msg.getPostDataParts()    
    querystring.stringify(data) + "\n"
    
exports = module.exports = Sender
