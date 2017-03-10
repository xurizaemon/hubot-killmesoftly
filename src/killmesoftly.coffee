# Description:
#   A message matching filter for what Hubot says.
#   - Commands allow killfile management.
#   - Response middleware intercepts messages and kills them.
#
module.exports = (robot) ->
  # Load|create a kill file (array of filter regex patterns).
  robot.brain.data.killfile ?= {
    enabled: true,
    entries: [
      {
        author: '@xurizaemon',
        pattern: 'GET .* FRIENDS',
        since: '2017-03-09',
      }
    ]
  }

  restore_killing = (status) ->
    @robot.brain.data.killfile.enabled = status

  # Ensure killfile is disabled for 1s so we can output replies
  # which contain killfile entries ... like showing the killfile!
  pause_killing = (status) ->
    if @robot.brain.data.killfile.enabled
      setTimeout (@robot) ->
        restore_killing true
      , 1000
      @robot.brain.data.killfile.enabled = false

  # Add an item to killfile.
  # @hubot kill: GET .* FRIENDS
  robot.respond /kill: (.*)/i, (res) ->
    pause_killing()
    res.match[1] = res.match[1]?.trim()
    # Do not add empty entries.
    return if !res.match[1]
    # Do not duplicate entries.
    for entry, index in robot.brain.data.killfile.entries
      if entry.pattern == res.match[1]
        res.reply "That's already in the killfile!"
        return
    robot.brain.data.killfile.entries.push {
      author: res.envelope.user.name,
      pattern: res.match[1],
      since: new Date().toISOString()
    }
    res.reply "OK #{res.envelope.user.name}, I will not say things matching /#{res.match[1]}/."

  # Show the current killfile.
  # @hubot show killfile
  robot.respond /show killfile/, (res) ->
    pause_killing()
    message = 'Current killfile:\n'
    for value, index in robot.brain.data.killfile.entries
      message += "#{index}: /#{value.pattern}/ (by #{value.author})\n"
    res.reply message

  # Remove an item from the killfile.
  # @hubot delete kill 3
  robot.respond /delete kill (.*)/, (res) ->
    pause_killing()
    if robot.brain.data.killfile.entries[res.match[1]]?
      entry = robot.brain.data.killfile.entries[res.match[1]]
      robot.brain.data.killfile.entries.splice(res.match[1], 1)
      res.reply "Removed entry #{res.match[1]}: #{entry.pattern}."

  # Activate/deactivate killfile.
  # @hubot killfile on|off
  robot.respond /killfile (on|off)/, (res) ->
    if res.match[1] == 'on'
      robot.brain.data.killfile.enabled = true
    else
      robot.brain.data.killfile.enabled = false
    res.reply "Killfile is #{robot.brain.data.killfile.enabled}"

  # Intercept things @hubot ought not to say.
  robot.responseMiddleware (context, next, done) ->
    return unless context.plaintext?
    for string in context.strings
      if robot.brain.data.killfile.enabled
        for entry in robot.brain.data.killfile.entries
          if string.match(entry.pattern)
            robot.logger.info "Matched /#{entry.pattern}/ (by #{entry.author}), so not saying \"#{string}\""
            context.strings = []
    next()
