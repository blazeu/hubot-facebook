# Setup stubs used by the other tests

{Facebook} = require '../index'
{EventEmitter} = require 'events'
# Use Hubot's brain in our stubs
{Brain} = require 'hubot'

# Stub a few interfaces to grease the skids for tests. These are intentionally
# as minimal as possible and only provide enough to make the tests possible.
# Stubs are recreated before each test.
beforeEach ->
  @stubs = {}
  @stubs.user =
    name: 'name'
    id: 'U123.foo'
  @stubs.self =
    name: 'self'
    firstName: 'self'
    id: 'U456.bar'
  @stubs.message =
    type: 'message'
    senderName: 'abc xyz'
    senderID: '123456789'
    participantNames: ['abc','foo bar']
    participantIDs: ['123456789','10089123769489']
    body: 'body'
    threadID: '116627323463939'
    threadName: 'name'
    messageID: 'mid.145986339'
    attachments: []
    timestamp: 1459863398567
  @stubs.sticker =
    type: "sticker"
    url: "http://abc.com"
    stickerID: "123343545"
  @stubs.state = [{'data': 'value'}]

  @stubs._msg = []
  @stubs._readed = {}
  @stubs._title = {}
  @stubs._typing =
    typed: true
  @stubs.bot =
    getCurrentUserID: => @stubs.self.id
    getUserInfo: (ids, cb) =>
      object = {}
      object[@stubs.self.id] = @stubs.self
      cb null, object
    listen: (cb) => cb null, @stubs.message
    markAsRead: (threadID, cb) =>
      @stubs._readed[threadID] = true
      cb() if cb?
    sendMessage: (message, threadID, cb) =>
      @stubs._msg.push
        msg: message
        thread: threadID
      cb() if cb?
    setTitle: (title, thread, cb) =>
      @stubs._title[thread] = title
      cb() if cb?
    sendTypingIndicator: (thread, cb) =>
      @stubs._typing[thread] = true
      cb()
    getAppState: => @stubs.state

  # Hubot.Robot instance
  @stubs.robot = do ->
    robot = new EventEmitter
    # noop the logging
    robot.logger =
      info: ->
      debug: ->
    # record all received messages
    robot.received = []
    robot.receive = (msg) ->
      @received.push msg
    robot.listeners = []
    # attach a real Brain to the robot
    robot.brain = new Brain robot
    robot

# Generate a new facebook instance for each test.
beforeEach ->
  @facebook = new Facebook @stubs.robot
  @facebook.bot = @stubs.bot
