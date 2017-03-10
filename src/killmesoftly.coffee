# Description:
#   A message matching filter for what Hubot says.
#   - Commands allow killfile management.
#   - Response middleware intercepts messages and kills them.
#
module.exports = (robot) ->
  # Load|create a kill file (array of filter regex patterns).
  robot.brain.data.killfile = {
    enabled: true,
    entries: [
      {
        author: '@xurizaemon',
        pattern: 'GET .* FRIENDS',
        since: '2017-03-09',
      }
    ]
  }

  # Reset to defaults.
  reset_defaults = () ->
    @robot.brain.data.killfile = {
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
    @robot.logger.info 'restore'
    @robot.logger.info status
    @robot.brain.data.killfile.enabled = status
    @robot.logger.info @robot.brain.data.killfile

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
    if res.match[1]
      res.match[1] = res.match[1].trim()
      robot.brain.data.killfile.entries.push {
        author: '@someone',
        pattern: res.match[1],
        since: '2017-03-09'
      }
      res.reply "OK, I will not say things matching /#{res.match[1]}/."

  # Show the current killfile.
  # @hubot show killfile
  robot.respond /show killfile/, (res) ->
    pause_killing()
    robot.logger.info robot.brain.data.killfile
    message = 'Current killfile:\n'
    for value, index in robot.brain.data.killfile.entries
      message += "#{index}: /#{value.pattern}/ (by #{value.author})\n"
    res.reply message

  # Remove an item from the killfile.
  # @hubot delete kill 3
  robot.respond /delete kill ([d]+)/, (res) ->
    pause_killing()
    if robot.brain.data.killfile[d]?
      robot.brain.data.killfile.splice(res.match[1], 1)
    res.reply 'Removed entry #{res.match[1]}.'

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
    # reset_defaults
    robot.logger.info "enabled: #{robot.brain.data.killfile.enabled}"
    robot.logger.info "entries: #{robot.brain.data.killfile.entries}"

    # robot.logger.info context
    return unless context.plaintext?
    for string in context.strings
      if robot.brain.data.killfile.enabled
        for entry in robot.brain.data.killfile.entries
          robot.logger.info JSON.stringify(entry.pattern)
          # pattern = new Regexp(entry.pattern)
          if string.match(entry.pattern)
            robot.logger.info "Matched /#{entry.pattern}/ (by #{entry.author}), so not saying \"#{string}\""
            context.strings = []
    next()
