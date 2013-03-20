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
votes = {}
currentTrack = null

module.exports = (robot) ->
  io = require('socket.io').listen 8081
  io.sockets.on 'connection', (socket) ->
    socket.emit 'welcome', name: robot.name
    socket.on 'trackchnge', (data) ->
      user = {}
      user.room = room if room

      artist = data.data.artists[0].name
      track  = data.data.name
      year   = data.data.album.year

      robot.send user, "Now Playing: #{track} by #{artist} from #{year}"

      total = tally()
      if total
        socket.emit 'trackdrop', currentTrack

      currentTrack = data.data
      votes = {}

    socket.on 'join', (data) ->
      room = data

  robot.respond /spotify (\+|-)1/i, (msg) ->
    now = new Date()
    votes[msg.message.user.id] =
      user: msg.message.user
      term: if msg.match[1] is '+' then 1 else -1
      time: now.getTime()

  tally = ->
    total = 0
    for userId, vote of votes
      total += vote.term
    total
