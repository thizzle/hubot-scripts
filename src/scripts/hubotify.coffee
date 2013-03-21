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
#   hubot spotify current
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

      total = tally()
      if total
        socket.emit 'trackdrop', currentTrack
        robot.send user, "Removing '#{currentTrack.name}' from the playlist"

      currentTrack = data.data
      votes = {}

      artist = currentTrack.artists[0].name
      track  = currentTrack.name
      year   = currentTrack.album.year

      robot.send user, "Now Playing: #{track} by #{artist} from #{year}"

    socket.on 'join', (data) ->
      room = data

  robot.respond /spotify current/i, (msg) ->
    artist = currentTrack.artists[0].name
    track  = currentTrack.name
    year   = currentTrack.album.year

    msg.send "Now Playing: #{track} by #{artist} from #{year}"

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
