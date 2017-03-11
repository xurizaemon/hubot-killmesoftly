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
#   hubot refrain (on|off) - Activate/deactivate refrain.
#   hubot refrain show - Print the list of patterns to exclude.
#   hubot refrain add <pattern> - Add refrain entry
#   hubot refrain remove <N> - Delete refrain entry (by index)
#
# Author:
#   Chris Burgess <chris@giantrobot.co.nz>
module.exports = (robot) ->
  # Handle rename.
  if robot.brain.data.killfile && !robot.brain.data.refrain
    robot.logger.info "Moving killfile to refrain."
    robot.brain.data.refrain = robot.brain.data.killfile

  # Load|create a kill file (array of filter regex patterns).
  robot.brain.data.refrain ?= {
    # Interception is enabled or disabled.
    enabled: true,
    # Entries to intercept.
    # [{pattern: '(what)', author: '(who)', since: '(time)'}]
    entries: []
  }

  restore_refrain = (status) ->
    @robot.brain.data.refrain.enabled = status

  # Ensure refrain is disabled briefly so we can output replies
  # containing refrain entries ... eg the refrain!
  pause_refrain = (status) ->
    if @robot.brain.data.refrain.enabled
      @robot.brain.data.refrain.enabled = false
      setTimeout (@robot) ->
        restore_refrain true
      , 1000

  # Show the current refrain.
  # @hubot show refrain
  robot.respond /refrain show/, (res) ->
    pause_refrain()
    if robot.brain.data.refrain.entries.length > 0
      message = []
      message.push 'Current refrain entries:'
      for value, index in robot.brain.data.refrain.entries
        message.push " #{index}: /#{value.pattern}/ (by #{value.author})"
      message = message.join '\n'
    else
      message = 'No current refrain entries.'
    res.reply message

  # Add an item to refrain.
  # @hubot refrain add GET .* FRIENDS
  robot.respond /refrain add (.*)/i, (res) ->
    pause_refrain()
    res.match[1] = res.match[1]?.trim()
    # Do not add empty entries.
    return if !res.match[1]
    # Do not duplicate entries.
    for entry, index in robot.brain.data.refrain.entries
      if entry.pattern == res.match[1]
        res.reply "That's already in the refrain!"
        return
    robot.brain.data.refrain.entries.push {
      author: res.envelope.user.name,
      pattern: res.match[1],
      since: new Date().toISOString()
    }
    res.reply "OK, I will not say things matching /#{res.match[1]}/."

  # Remove an item from the refrain.
  # @hubot delete kill 3
  robot.respond /refrain remove (.*)/, (res) ->
    pause_refrain()
    if robot.brain.data.refrain.entries[res.match[1]]?
      entry = robot.brain.data.refrain.entries[res.match[1]]
      robot.brain.data.refrain.entries.splice(res.match[1], 1)
      res.reply "Removed entry #{res.match[1]}: #{entry.pattern}."

  # Activate/deactivate refrain.
  # @hubot refrain on|off
  robot.respond /refrain (on|off)/, (res) ->
    if res.match[1] == 'on'
      robot.brain.data.refrain.enabled = true
    else
      robot.brain.data.refrain.enabled = false
    res.reply "refrain is #{robot.brain.data.refrain.enabled}"

  # Intercept things @hubot ought not to say.
  robot.responseMiddleware (context, next, done) ->
    return unless context.plaintext?
    if robot.brain.data.refrain.enabled
      for string in context.strings
        for entry in robot.brain.data.refrain.entries
          if string.match(entry.pattern)
            robot.logger.info "Matched /#{entry.pattern}/ (by #{entry.author}), so not saying \"#{string}\""
            context.strings = []
    next()
