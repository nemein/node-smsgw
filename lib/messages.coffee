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

uuid = require 'node-uuid'

class Message
  @MAX_SENDER_LENGTH = 16
  @AVAILABLE_CLASSES = ["normal", "flash"]
  
  id: null
  deliveryTime: null
  validityPeriod: null
  keywords: null
  operator: null
  parameters: {}
  recipients: []
  sender: null
  serviceName: null
  serviceNumber: null
  text: null
  binary: null
  msg_class: "normal"
  unicode: false
  concatenate: false
  header: null
  wap_text: null
  wap_url: null  
  report_url: null
  
  _serialize_attrs: [
    'parser', 'id', 'deliveryTime', 'validityPeriod', 'keywords', 'operator', 'parameters',
    'recipients', 'sender', 'serviceName', 'serviceNumber', 'text', 'binary', 'msg_class', 'unicode',
    'concatenate', 'header', 'wap_text', 'wap_url', 'report_url'
  ]
    
  parser: null

  constructor: (receiver, content) ->    
    @id = uuid()
    if receiver
      @addRecipient receiver
    if content
      @setText content
  
  setText: (text) ->
    @text = text
    @binary = null
    @wap_text = null
    @wap_url = null
    
  setBinary: (binary) ->
    @binary = binary
    @text = null
    @wap_text = null
    @wap_url = null

  setWapText: (text) ->
    @wap_text = text
    @binary = null
    @text = null

  setWapUrl: (url) ->
    @wap_url = url
    @binary = null
    @text = null

  addRecipient: (receiver) ->    
    @recipients.push receiver unless @hasRecipient receiver
  
  hasRecipient: (receiver) ->
    true if receiver in @recipients
    false
    
  setSender: (sender) ->
    if sender and sender.length <= Message.MAX_SENDER_LENGTH
      @sender = sender
  
  setService: (number, name) ->
    @serviceNumber = number
    @serviceName = name
  
  setRelativeDeliveryTime: (minutes) ->
    #TODO: Validation of minutes
    if minutes and minutes > 0
      @deliveryTime = minutes
    
  setAbsoluteDeliveryTime: (datetime) ->
    #TODO: Validation of datetime
    if datetime
      @deliveryTime = datetime
      
  setRelativeValidityPeriod: (minutes) ->
    #TODO: Validation of minutes
    if minutes and minutes > 0
      @validityPeriod = minutes

  setAbsoluteValidityPeriod: (datetime) ->
    #TODO: Validation of datetime
    if datetime
      @validityPeriod = datetime
  
  setReportUrl: (@report_url) ->
  getReportUrl: ->
    @report_url
    
  getContent: ->
    if @binary
      return @binary
    return @text
  
  getPostDataParts: ->
    return {}
    
  toObject: () ->
    return {
      type: @__proto__.constructor.name
      id: @id
      recipients: @recipients
      sender: @sender
      operator: @operator
      keywords: @keywords
      parameters: @parameters
      content: @getContent()      
    }
  
  toJSON: ->
    vals = {type: @__proto__.constructor.name}
    
    for key in @_serialize_attrs
      vals[key] = @[key]
    
    JSON.stringify vals
  
  fromJSON: (data) ->
    for key in @_serialize_attrs
      @[key] = data[key]
    
class SMS extends Message
  @MAX_HEADER_LENGTH = 140
  
  contructor: (receiver, content) ->    
    super reciever, content    
  
  setHeader: (header) ->
    if header and header <= SMSMessage.MAX_HEADER_LENGTH
      @header = header
      @wap_text = null
      @wap_url = null
  
  setWapPush: (url, description) ->
    @setWapUrl url
    @setWapText description    
    @concatenate = true
    @unicode = false

  getPostDataParts: () ->
    parts =
      dests: @recipients.join ","
    
    if @text
      parts['text'] = @text
    if @binary
      parts['binary'] = @binary
    if @serviceName
      parts['source-name'] = @serviceName
    if @serviceNumber
      parts['source'] = @serviceNumber
      
    if @msg_class isnt "normal"
      parts['class'] = @msg_class
      
    return parts

class MMS extends Message
  @MAX_SUBJECT_LENGTH = 40  
  
  subject: null
  adaptations: false
  autoSmil: false
  objects: []
  
  contructor: (receiver, content) ->    
    super reciever, content    
    @_serialize_attrs = @_serialize_attrs.concat ['subject', 'adaptations', 'autoSmil', 'ser_objects']
  
  setSubject: (subject) ->
    if subject and subject.length <= MMSMessage.MAX_SUBJECT_LENGTH
      @subject = subject
  
  addObject: (obj) ->
    if obj is MMSObject
      @objects.push obj
  
  getText: () ->
    if @text
      @text
    for obj in @objects
      if obj.isText
        obj.content
  
  toJSON: ->
    @ser_objects = {}
    for obj in @objects
      @ser_objects.push obj.serialize()
    super()

class MMSObject  
  @FORMAT_BINARY = "binary"
  @FORMAT_FILE = "file"
  @FORMAT_TEXT = "text"
  
  content: null
  filename: null
  format: null
  content_type: null
  
  getContentLength: () ->
    if @isText() or @isBinary()
      @content.length
    else
      #TODO: find out filesize
      return 0
  
  isText: () ->
    @content_type is MMSObject.FORMAT_TEXT

  isBinary: () ->
    @content_type is MMSObject.FORMAT_BINARY
  
  setBinaryContent: (bytes) ->
    @content_type = MMSObject.FORMAT_BINARY
    @content = bytes
    
  setTextContent: (text) ->
    @content_type = MMSObject.FORMAT_TEXT
    @content = text
  
  serialize: -> return {}

class DeliveryReport
  @STATE_DELIVERED = "OK"
  @STATE_WAITING = "WAITING"
  @STATE_FAILED = "ERROR"

  message_id: null
  state: null
  error: null
  description: null
  original_recipient: null
  recipient: null
  
  _serialize_attrs: [
    "message_id", "state", "error", "error_msg", "description", "original_recipient", "recipient"
  ]

  constructor: (@recipient, @original_recipient, @state, @error, @description, @message_id) ->
    return

  isDelivered: () ->
    @state == DeliveryReport.STATE_DELIVERED

  isDelayed: () ->
    @state == DeliveryReport.STATE_WAITING

  isFailed: () ->
    @state == DeliveryReport.STATE_FAILED

  getErrorMessage: () ->
    switch @error
      when 0 then "OK"
      when 1 then "Unknown error"
      when 2 then "Invalid recipient"
      when 3 then "Unreachable recipient"
      when 4 then "Barred recipient"
      when 5 then "Subscription recipient"
      when 6 then "Expired"
      when 7 then "Routing"
      when 8 then "Network"
      when 9 then "Capacity"
      when 10 then "Operator"
      when 11 then "Protocol"
      when 12 then "Canceled"
  
  toObject: () ->
    return {
      type: @__proto__.constructor.name
      id: @message_id
      recipient: @recipient
      original_recipient: @original_recipient
      state: @state
      error: @error
      error_msg: @getErrorMessage()
      description: @description 
    }
    
  toJSON: ->
    vals = 
      type: @__proto__.constructor.name
      error_msg: @getErrorMessage()

    for key in @_serialize_attrs
      vals[key] = @[key]

    JSON.stringify vals

  fromJSON: (data) ->
    for key in @_serialize_attrs
      @[key] = data[key]

module.exports.SMS = SMS
module.exports.MMS = MMS
module.exports.DeliveryReport = DeliveryReport

module.exports.serialize = (message) ->
  message.toJSON()
module.exports.unserialize = (data) ->
  data = JSON.parse data
  
  message_class = SMS
  if data.type
    if data.type == 'MMS'
      message_class = MMS
    else if data.type == 'DeliveryReport'
      message_class = DeliveryReport
  
  msg = new message_class()
  msg.fromJSON data
  
  msg
