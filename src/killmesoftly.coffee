# Description:
#   A message matching filter for Hubot's replies. Allows Hubot to *not* say
#   things based on a set of patterns stored in robot.brain.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot killfile (on|off) - Activate/deactivate killfile.
#   hubot killfile show - Print the list of patterns to exclude.
#   hubot killfile add <pattern> - Add killfile entry
#   hubot killfile remove <N> - Delete killfile entry (by index)
#
module.exports = (robot) ->
  # Load|create a kill file (array of filter regex patterns).
  robot.brain.data.killfile ?= {
    # Interception is enabled or disabled.
    enabled: true,
    # Entries to intercept.
    # [{pattern: '(what)', author: '(who)', since: '(time)'}]
    entries: []
  }

  restore_killing = (status) ->
    @robot.brain.data.killfile.enabled = status

  # Ensure killfile is disabled briefly so we can output replies
  # containing killfile entries ... eg the killfile!
  pause_killing = (status) ->
    if @robot.brain.data.killfile.enabled
      @robot.brain.data.killfile.enabled = false
      setTimeout (@robot) ->
        restore_killing true
      , 1000

  # Show the current killfile.
  # @hubot show killfile
  robot.respond /killfile show/, (res) ->
    pause_killing()
    message = 'Current killfile:\n'
    for value, index in robot.brain.data.killfile.entries
      message += "#{index}: /#{value.pattern}/ (by #{value.author})\n"
    res.reply message

  # Add an item to killfile.
  # @hubot kill: GET .* FRIENDS
  robot.respond /killfile add (.*)/i, (res) ->
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
    res.reply "OK, I will not say things matching /#{res.match[1]}/."

  # Remove an item from the killfile.
  # @hubot delete kill 3
  robot.respond /killfile remove (.*)/, (res) ->
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
