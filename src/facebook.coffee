{Robot, Adapter, TextMessage, EnterMessage, LeaveMessage, TopicMessage, Response, Brain} = require 'hubot'

chat = require 'facebook-chat-api'
FB = require 'fb'

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
      @bot.sendMessage str, envelope.room

  sendPrivate: (envelope, strings...) ->
    @send room: envelope.user.id, strings...

  sendSticker: (envelope, ids...) ->
    for id in ids
      @bot.sendSticker id, envelope.room

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

    # Override the response to provide custom method
    @robot.Response = FbResponse

    chat (err, bot) ->
      return self.robot.logger.error err if err

      # Mute fb-chat-api's logging and allow listen for events
      bot.setOptions({logLevel: "silent", listenEvents: true})

      self.bot = bot

      if not config.name?
        FB.setAccessToken bot.getAccessToken()
        FB.api 'me', (res) ->
          # set robot name to first name of the faceobok account
          config.name = res.first_name
          self.robot.name = config.name
          self.emit "connected"
      else
        self.emit "connected"

      bot.listen (err, event, stop) ->
        return self.robot.logger.error err if err

        sender = event.sender_id or event.author
        user = self.robot.brain.userForId sender, name: event.sender_name, room: event.thread_id

        switch event.type
          when "message"
            self.receive new TextMessage user, event.body
          when "event"
            switch event.log_message_type
              when "log:thread-name"
                self.receive new TopicMessage user, event.log_message_data.name
              when "log:unsubscribe"
                self.receive new LeaveMessage user
              when "log:subscribe"
                self.receive new EnterMessage user
          when "sticker"
            # TODO: Add a custom StickerMessage
            self.receive new TextMessage user, event.sticker_id.toString()

        self.robot.logger.debug "#{user.name} -> #{user.room}: #{event.body || event.log_message_type}"

exports.use = (robot) ->
  new Facebook robot
