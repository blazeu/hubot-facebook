{Listener} = require 'hubot'
{StickerMessage} = require './message'

# Custome listener for custom messager
# Ex:
# HubotFacebook = require 'hubot-facebook'
# module.exports = (robot) ->
#   robot.listeners.push new HubotFacebook.StickerListener robot, /^foo/, (msg) ->
#    msg.send "bar"
#

class StickerListener extends Listener
  constructor: (@robot, @regex, @callback) ->
    @matcher = (message) =>
      if message instanceof StickerMessage
        message.match @regex

  call: (message) ->
    if message instanceof StickerMessage
      super message
    else
      false

module.exports = {
  StickerListener
}
