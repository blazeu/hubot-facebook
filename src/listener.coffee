{Listener} = require 'hubot'
{CustomFacebookMessage, StickerMessage} = require './message'

# Custome listener for custom messager
# Ex:
# HubotFacebook = require 'hubot-facebook'
# module.exports = (robot) ->
#   robot.listeners.push new HubotFacebook.StickerListener robot, /^foo/, (msg) ->
#    msg.send "bar"
#

class CustomFacebookListener extends Listener
  constructor: (@robot, @regex, @callback) ->
    @matcher = (message) =>
      if message instanceof CustomFacebookMessage
        message.fields.type.match @regex

  call: (message) ->
    if message instanceof CustomFacebookMessage
      super message
    else
      false

class StickerListener extends CustomFacebookListener
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
  CustomFacebookListener
  StickerListener
}
