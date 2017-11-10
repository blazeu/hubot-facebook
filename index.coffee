Facebook = require './src/facebook'
{CustomFacebookMessage, StickerMessage} = require './src/message'
{CustomFacebookListener, StickerListener} = require './src/listener'

module.exports = exports = {
  Facebook
  CustomFacebookMessage
  StickerMessage
  CustomFacebookListener
  StickerListener
}

exports.use = (robot) ->
  new Facebook robot
