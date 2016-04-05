{Message, TextMessage} = require 'hubot'

# Hubot only started exporting Message in 2.11.0. Previous version do not export
# this class. In order to remain compatible with older versions, we can pull the
# Message class from TextMessage superclass.
if not Message
  Message = TextMessage.__super__.constructor

class StickerMessage extends Message
  # Represents Sticker messages.
  #
  #
  # user       - The User object
  # text       - The sticker url
  # id         - The id of message
  # stickerID  - The id of sticker
  constructor: (@user, @text="", @id="", @fields={}) ->
    super @user

  match: (regex) ->
    @fields.stickerID.match regex

  toString: () ->
    "Sticker(#{@fields.stickerID})"

module.exports = {
  StickerMessage
}
