{Facebook} = require '../index'

should = require 'should'
fs = require 'fs'

describe 'Adapter', ->
  it 'Should initialize with a robot', ->
    @facebook.robot.should.eql @stubs.robot

describe 'Login', ->
  it 'Should set the robot name', ->
    @facebook.setName =>
      @facebook.robot.name.should.equal @stubs.self.name

describe 'Send Messages', ->
  it 'Should send multiple messages', ->
    @facebook.send {room: 'general'}, 'one', 'two', 'three'
    @stubs._msg.length.should.equal 3

  it 'Should not send empty messages', ->
    @facebook.send {room: 'general'}, 'Hello', '', '', 'world!'
    @stubs._msg.length.should.equal 2

describe 'Send Private Messages', ->
  it 'Should send multiple message', ->
    @facebook.sendPrivate {user: id: 'name'}, 'one', 'two', 'three'
    @stubs._msg.length.should.equal 3
    @stubs._msg[0].msg.body.should.eql 'one'
    @stubs._msg[0].thread.should.eql 'name'

  it 'Should not send empty messages', ->
    @facebook.sendPrivate {user: id: 'name'}, 'Hello', '', '', 'world!'
    @stubs._msg.length.should.equal 2

describe 'Send Sticker Messages', ->
  it 'Should send multiple sticker', ->
    @facebook.sendSticker {room: 'general'}, 'pusheen1', 'pusheen2'
    @stubs._msg.length.should.equal 2
    @stubs._msg[0].msg.sticker.should.eql 'pusheen1'

describe 'Send Typing Indicator', ->
  it 'Should start typing indicator', ->
    @facebook.typing {room: 'general'}
    @stubs._typing.general.should.equal true

  it 'Should stop typing indicator', ->
    @facebook.endTyping = =>
      @stubs._typing['typed'] = false
    @facebook.typing {room: 'typed'}, false
    @stubs._typing.typed.should.equal false

describe 'App State', ->
  afterEach (done) ->
    fs.unlink @facebook.stateFile, -> done()

  it 'Should store', (done) ->
    @facebook.storeState (err) =>
      fs.readFile @facebook.stateFile, (err, data) =>
        data = JSON.parse data
        data.should.eql @stubs.state
        done()

  it 'Should get from cache file', ->
    state = JSON.stringify @stubs.state
    fs.writeFileSync @facebook.stateFile, state
    @facebook.getState().should.eql @stubs.state

describe 'Get User Info', ->
  it 'Should get', (done) ->
    @facebook.getUser @stubs.self.id, (user) =>
      user.should.eql @stubs.self
      done()

# TODO test send file

describe 'Other action', ->
  it 'Should mark as read', ->
    @facebook.read {room: 'general'}
    @stubs._readed.general.should.equal true

  it 'Should reply a message', ->
    @facebook.reply {room: 'general', message: user: name: "user"}, "test"
    @stubs._msg.length.should.equal 1
    @stubs._msg[0].msg.body.should.eql '@user test'

  it 'Should not add prefix if reply in private room', ->
    @facebook.reply {room: 'user', message: user: id: "user"}, "test"
    @stubs._msg.length.should.equal 1
    @stubs._msg[0].msg.body.should.eql 'test'

  it 'Should reply a message only with first name', ->
    @facebook.reply {room: 'general', message: user: name: "first last"}, "test"
    @stubs._msg.length.should.equal 1
    @stubs._msg[0].msg.body.should.eql '@first test'

  it 'Should set topic', ->
    @facebook.topic {room: 'general'}, 'test1', 'test2'
    @stubs._title.general.should.eql 'test1 test2'
