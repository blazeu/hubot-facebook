Facebook = require './src/facebook'
{StickerMessage} = require './src/message'
{StickerListener} = require './src/listener'

module.exports = exports = {
  Facebook
  StickerMessage
  StickerListener
}

exports.use = (robot) ->
  new Facebook robot
