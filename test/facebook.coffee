{Facebook} = require '../index'

should = require 'should'

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

# TODO test send file

describe 'Other action', ->
  it 'Should mark as read', ->
    @facebook.read {room: 'general'}
    @stubs._readed.general.should.equal true

  it 'Should reply a message', ->
    @facebook.reply {room: 'general', message: user: name: "user"}, "test"
    @stubs._msg.length.should.equal 1
    @stubs._msg[0].msg.body.should.eql '@user test'

  it 'Should reply a message only with first name', ->
    @facebook.reply {room: 'general', message: user: name: "first last"}, "test"
    @stubs._msg.length.should.equal 1
    @stubs._msg[0].msg.body.should.eql '@first test'

  it 'Should set topic', ->
    @facebook.topic {room: 'general'}, 'test1', 'test2'
    @stubs._title.general.should.eql 'test1 test2'
