{Robot, Adapter, TextMessage, EnterMessage, LeaveMessage, TopicMessage, Response, Brain} = require 'hubot'
{StickerMessage} = require './message'
{StickerListener} = require './listener'

fs = require 'fs'
chat = require 'facebook-chat-api'

# Custom Response class that adds a sendPrivate method (based on hubot-irc) and sendSticker method
class FbResponse extends Response
  sendPrivate: (strings...) ->
    @robot.adapter.sendPrivate @envelope, strings...

  sendSticker: (ids...) ->
    @robot.adapter.sendSticker @envelope, ids...

  sendFile: (string, file_streams...) ->
    @robot.adapter.sendFile @envelope, string, file_streams...

  read: () ->
    @robot.adapter.read @envelope

  typing: (start) ->
    @robot.adapter.typing @envelope, start

class Facebook extends Adapter
  stateFile: "#{__dirname}/../state.json"

  send: (envelope, strings...) ->
    for str in strings
      continue unless str
      msg = {body: str}
      @bot.sendMessage msg, envelope.room

  sendPrivate: (envelope, strings...) ->
    @send room: envelope.user.id, strings...

  sendSticker: (envelope, ids...) ->
    for id in ids
      msg = {sticker: id}
      @bot.sendMessage msg, envelope.room

  sendFile: (envelope, string, file_streams...) ->
    msg = {body: string, attachment: file_streams}
    @bot.sendMessage msg, envelope.room

  read: (envelope) ->
    @bot.markAsRead envelope.room

  typing: (envelope, start = true) ->
    if not start then return @endTyping?()
    @endTyping = @bot.sendTypingIndicator envelope.room, (err) ->
      @robot.logger.error err if err

  reply: (envelope, strings...) ->
    if envelope.room == envelope.user?.id || envelope.room == envelope.message?.user?.id
      @send envelope, strings...
    else
      name = envelope.user?.name?.split(' ')[0] || envelope.message?.user?.name?.split(' ')[0]
      @send envelope, strings.map((str) -> "@#{name} #{str}")...

  topic: (envelope, strings...) ->
    title = strings.join(' ')
    thread = envelope.room
    @bot.setTitle title, thread

  customeMessage: (data) =>
    if data.user?.id || data.user?.name
      if data.user?.id
        room = data.user.id
      else
        user = @robot.brain.userForName data.user.name
        room = user.id if user?
    else if data.room?
      room = data.room

    unless room?
      room = if data.room
        data.room
      else if data.message.envelope
        data.message.envelope.room
      else data.message.room

    msg = {}
    msg.sticker = data.sticker if data.sticker?
    msg.body = data.text if data.text?
    msg.attachment = data.attachment || data.attachments

    @bot.sendMessage msg, room

  privateMessage: (data) =>
    user = data.message.user
    @customeMessage user: user

  message: (event) ->
    # Skip useless data
    return if event.type in ["typ", "read_receipt", "read", "presence"]

    sender = event.senderID or event.author or event.userID
    options = room: event.threadID
    name = event.senderName
    if event.participantNames? and event.participantIDs?
      name = event.participantNames[event.participantIDs.indexOf(sender)]
    options.name = name if name
    user = @robot.brain.userForId sender, options

    switch event.type
      when "message"
        if event.body?
          @robot.logger.debug "#{user.name} -> #{user.room}: #{event.body}"

          # If this is a PM, pretend it was addressed to us
          event.body = "#{@robot.name} #{event.body}" if "#{sender}" == "#{event.threadID}"

          @receive new TextMessage user, event.body, event.messageID

        for attachment in event.attachments
          switch attachment.type
            when "sticker"
              @robot.logger.debug "#{user.name} -> #{user.room}: #{attachment.stickerID}"
              @receive new StickerMessage user,
                (attachment.url || attachment.spriteURI2x || attachment.spriteURI),
                event.messageID, attachment
            # TODO "file", "photo", "animated_image", "share"
      when "event"
        switch event.logMessageType
          when "log:thread-name"
            @receive new TopicMessage user, event.logMessageData.name
          when "log:unsubscribe"
            @receive new LeaveMessage user
          when "log:subscribe"
            @receive new EnterMessage user
        @robot.logger.debug "#{user.name} -> #{user.room}: #{event.logMessageType}"

  setName: (cb) ->
    user_id = @bot.getCurrentUserID()
    @bot.getUserInfo user_id, (err, res) =>
      return @robot.logger.error err if err
      # set robot name to first name of the faceobok account
      @robot.name = res[user_id].firstName
      cb()

  getState: ->
    try
      return require(@stateFile)
    catch error
      return null

  storeState: (cb) ->
    state = JSON.stringify @bot.getAppState()
    fs.writeFile @stateFile, state, (err) =>
      return @robot.logger.error err if err?
      cb() if cb?

  run: ->
    # another way to use special send is use @robot.emit
    # so hubot don't need to check if respond has special method or not
    @robot.on "facebook.sendSticker", @.customeMessage
    @robot.on "facebook.sendImage", @.customeMessage
    @robot.on "facebook.sendFile", @.customeMessage
    @robot.on "facebook.sendPrivate", @.privateMessage

    config =
      name: if @robot.name is 'Hubot' then null else @robot.name
      credentials:
        email: process.env.HUBOT_FB_EMAIL || process.env.FB_LOGIN_EMAIL
        password: process.env.HUBOT_FB_PASSWORD || process.env.FB_LOGIN_PASSWORD
        appState: @getState()
      options:
        logLevel: 'silent'
        listenEvents: true
        forceLogin: true
        selfListen: if process.env.FB_SELF_LISTEN then true else false

    # Override the response to provide custom method
    @robot.Response = FbResponse
    @robot.respondSticker = (regex, callback) =>
      @robot.listeners.push new StickerListener @robot, regex, callback

    chat config.credentials, config.options, (err, bot) =>
      return @robot.logger.error err if err
      @robot.logger.info 'Logged in'

      @bot = bot

      @storeState()

      if config.name
        @emit "connected"
      else
        @setName => @emit "connected"


      bot.listen (err, event, stop) =>
        return @robot.logger.error err if err or not event?
        @message event


module.exports = Facebook
