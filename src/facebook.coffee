{Robot, Adapter, TextMessage, EnterMessage, LeaveMessage, TopicMessage, Response, Brain} = require 'hubot'
{StickerMessage} = require './message'
{StickerListener} = require './listener'

chat = require 'facebook-chat-api'

# Custom Response class that adds a sendPrivate method (based on hubot-irc) and sendSticker method
class FbResponse extends Response
  sendPrivate: (strings...) ->
    @robot.adapter.sendPrivate @envelope, strings...

  sendSticker: (ids...) ->
    @robot.adapter.sendSticker @envelope, ids...

  read: () ->
    @robot.adapter.read @envelope

class Facebook extends Adapter

  send: (envelope, strings...) ->
    for str in strings
      msg = {body: str}
      @bot.sendMessage msg, envelope.room

  sendPrivate: (envelope, strings...) ->
    @send room: envelope.user.id, strings...

  sendSticker: (envelope, ids...) ->
    for id in ids
      msg = {sticker: id}
      @bot.sendMessage msg, envelope.room

  sendImage: (envelope, string, file_streams...) ->
    msg = {body: string, attachment: file_streams}
    @bot.sendMessage msg, envelope.room

  read: (envelope) ->
    @bot.markAsRead envelope.room

  reply: (envelope, strings...) ->
    name = envelope.user.name.split(' ')[0]
    @send envelope, strings.map((str) -> "#{name}: #{str}")...

  topic: (envelope, strings...) ->
    title = strings.join(' ')
    thread = envelope.room
    @bot.setTitle title, thread

  run: ->
    self = @

    config =
      name: if @robot.name is 'hubot' then null else @robot.name
      email: process.env.HUBOT_FB_EMAIL || process.env.FB_LOGIN_EMAIL
      password: process.env.HUBOT_FB_PASSWORD || process.env.FB_LOGIN_PASSWORD

    # Override the response to provide custom method
    @robot.Response = FbResponse

    chat email: config.email, password: config.password, (err, bot) ->
      return self.robot.logger.error err if err

      # Mute fb-chat-api's logging and allow listen for events
      bot.setOptions({logLevel: "silent", listenEvents: true})

      self.bot = bot

      if not config.name?
        config.name = 'hubot'
        bot.getUserInfo bot.getCurrentUserID(), (err, res) ->
          return self.robot.logger.error err if err
          # set robot name to first name of the faceobok account
          for prop of res
            config.name = res[prop].firstName if (res.hasOwnProperty(prop) && res[prop].firstName)
          self.robot.name = config.name
          self.emit "connected"
      else
        self.emit "connected"

      bot.listen (err, event, stop) ->
        return self.robot.logger.error err if err or !event

        # Skip useless data
        return if !!~["typ", "read_receipt", "read", "presence"].indexOf(event.type)

        sender = event.senderID or event.author or event.userID
        user = self.robot.brain.userForId sender, name: event.senderName, room: event.threadID

        switch event.type
          when "message"
            if event.body
              self.robot.logger.debug "#{user.name} -> #{user.room}: #{event.body}"
              self.receive new TextMessage user, event.body

              # If this is a PM, pretend it was addressed to us
              event.body = "#{@robot.name} #{event.body}" if sender == event.threadID

            for attachment in event.attachments
              switch attachment.type
                when "sticker"
                  self.robot.logger.debug "#{user.name} -> #{user.room}: #{attachment.stickerID}"
                  self.receive new StickerMessage user, attachment.stickerID,
                    (attachment.spriteURI2x || attachment.spriteURI)
                # TODO "file", "photo", "animated_image", "share"
          when "event"
            switch event.logMessageType
              when "log:thread-name"
                self.receive new TopicMessage user, event.logMessageData.name
              when "log:unsubscribe"
                self.receive new LeaveMessage user
              when "log:subscribe"
                self.receive new EnterMessage user
            self.robot.logger.debug "#{user.name} -> #{user.room}: #{event.logMessageType}"

module.exports = exports = {
  Facebook
  StickerMessage
  StickerListener
}

exports.use = (robot) ->
  new Facebook robot
