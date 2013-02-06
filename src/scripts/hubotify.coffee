# Description
#   Real-time communication with Spotify
#
# Dependencies:
#   socket.io >= 0.9.x
#
# Configuration:
#   None
#
# Commands:
#   hubot spotify +1
#   hubot spotify -1
#
# Notes:
#   None
#
# Author:
#   Tharsan Bhuvanendran <me@tharsan.com>

room = ""

module.exports = (robot) ->
  io = require('socket.io').listen(robot.server)
  io.sockets.on 'connection', (socket) ->
    socket.emit 'welcome', name: robot.name
    socket.on 'trackchnge', (data) ->
      user = {}
      user.room = room if room

      artist = data.data.artists[0].name
      track  = data.data.name
      year   = data.data.album.year

      robot.send user, "Now Playing: #{track} by #{artist} from #{year}"

    socket.on 'join', (data) ->
      room = data

