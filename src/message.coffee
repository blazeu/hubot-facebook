{Message, TextMessage} = require 'hubot'

# Hubot only started exporting Message in 2.11.0. Previous version do not export
# this class. In order to remain compatible with older versions, we can pull the
# Message class from TextMessage superclass.
if not Message
  Message = TextMessage.__super__.constructor

class StickerMessage extends Message
  constructor: (@user, @sticker_id="", @raw_data = {}) ->
    super @user

  match: (regex) ->
    @sticker_id.match regex

  toString: () ->
    @sticker_id

module.exports = {
  StickerMessage
}
