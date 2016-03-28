{Message, TextMessage} = require 'hubot'

# Hubot only started exporting Message in 2.11.0. Previous version do not export
# this class. In order to remain compatible with older versions, we can pull the
# Message class from TextMessage superclass.
if not Message
  Message = TextMessage.__super__.constructor

class StickerMessage extends Message
  constructor: (@user, @stickerID="", @spriteURI="") ->
    super @user, @sticker_url

  match: (regex) ->
    @stickerID.match regex

  text: () ->
    @spriteURI

  toString: () ->
    "Sticker(#{@stickerID})"

module.exports = {
  StickerMessage
}
