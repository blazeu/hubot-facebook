{StickerMessage, StickerListener} = require '../index'
{TextMessage} = require 'hubot'

should = require 'should'

class FacebookMessage
  constructor: (fields = {}) ->
    @type = 'message'
    @attachments = []
    @[k] = val for own k, val of fields

describe 'Receiving a Facebook message', ->
  beforeEach ->
    @makeMessage = (fields = {}) =>
      msg = new FacebookMessage fields
      msg.senderID = @stubs.message.senderID unless 'senderID' of fields
      msg.threadID = @stubs.message.threadID unless 'threadID' of fields
      msg

  it 'should produce a TextMessage', ->
    @facebook.message @makeMessage {
      body: 'Hello world'
    }
    @stubs.robot.received.should.have.length 1
    msg = @stubs.robot.received[0]
    msg.should.be.an.instanceOf TextMessage
    msg.text.should.equal 'Hello world'

  it 'should produce a StickerMessage when the attachment type is sticker', ->
    @facebook.message rawMsg = @makeMessage {
      attachments: [{
        type: 'sticker'
        stickerID: 'abc'
        url: 'http://abc.com'
      }]
    }
    @stubs.robot.received.should.have.length 1
    msg = @stubs.robot.received[0]
    msg.should.be.an.instanceOf StickerMessage
    msg.text.should.equal 'http://abc.com'
    msg.fields.stickerID.should.equal 'abc'
