{Message, TextMessage} = require 'hubot'

# Hubot only started exporting Message in 2.11.0. Previous version do not export
# this class. In order to remain compatible with older versions, we can pull the
# Message class from TextMessage superclass.
if not Message
  Message = TextMessage.__super__.constructor

class CustomFacebookMessage extends Message
  # Represents facebook attachment messages.
  #
  #
  # user       - The User object
  # id         - The id of message
  # fields     - The facebook attachment of message
  constructor: (@user, @id, @fields={}) ->
    super @user

  toString: () ->
    "CustomMessage[#{@id}]"

class StickerMessage extends CustomFacebookMessage
  constructor: (@user, @id, @fields={}) ->
    super @user, @id, @fields
    @text = @fields.url || @fields.spriteURI2x || @fields.spriteURI

  match: (regex) ->
    @fields.stickerID.match regex

  toString: () ->
    "Sticker(#{@fields.stickerID})"

module.exports = {
  CustomFacebookMessage
  StickerMessage
}
