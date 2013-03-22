# Description
#   Real-time communication with Spotify allows partcipants in a room to receive
#   broadcast updates about track changes, and vote up/down tracks during playback
#
# Dependencies:
#   socket.io >= 0.9.x
#
# Configuration:
#   None
#
# Commands:
#   hubot spotify +1      - vote up the current playing track
#   hubot spotify like    - vote up the current playing track
#   hubot spotify -1      - vote down the current playing track
#   hubot spotify hate    - vote down the current playing track
#   hubot spotify current - show the current playing track info
#
# Notes:
#   None
#
# Author:
#   Tharsan Bhuvanendran <me@tharsan.com>

room = ""
votes = {}
currentTrack = null
spotify = null

trackdropMessages = [
  "{{artist}} doesn't have a lot of fans around here.",
  "Why does everybody hate {{artist}} so much?"
]

module.exports = (robot) ->
  io = require('socket.io').listen 8081
  io.sockets.on 'connection', (socket) ->
    spotify = socket
    socket.emit 'welcome', name: robot.name
    socket.on 'trackchnge', (data) ->
      user = {}
      user.room = room if room

      [ total, duration ] = tally()
      if total < -1
        trackdrop()

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

  robot.respond /spotify (\+1|-1|like|hate)/i, (msg) ->
    now = new Date()
    votes[msg.message.user.id] =
      user: msg.message.user
      term: if msg.match[1] in ['+1', 'like'] then 1 else -1
      time: now.getTime()

    [ total, duration ] = tally()
    if duration < 15 and total < -2
      trackdrop()
      if spotify
        spotify.emit 'play:next'

  trackdrop = ->
    return unless currentTrack

    user = {}
    user.room = room if room

    artist = currentTrack.artists[0].name
    track  = currentTrack.name
    year   = currentTrack.album.year

    idx = Math.round Math.random() * trackdropMessages.length - 1
    message = trackdropMessages[idx]
    message = message.replace '{{artist}}', artist
    message = message.replace '{{track}}', track
    message = message.replace '{{year}}', year

    if spotify
      spotify.emit 'trackdrop', currentTrack

    robot.send user, "#{message} Removing '#{currentTrack.name}' from the playlist"

  tally = ->
    start = null
    end = null
    total = 0

    for userId, vote of votes
      total += vote.term
      if start is null or vote.time < start
        start = vote.time

      if end is null or vote.time > end
        end = vote.time

    [ total, Math.round((end - start) / 1000) ]

