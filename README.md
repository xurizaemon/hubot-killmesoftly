# Hubot killfile / spam filter.

A pattern-based community killfile for outgoing Hubot messages. Implements a middleware to intercept messages Hubot is about to post, prevents matched message being output.

Perhaps you'd like to prevent Hubot being trained to swear, or you use [hubot-twitter-mention](https://github.com/vspiewak/hubot-twitter-mention) but you want to filter out some returned Tweets.

Uses `robot.brain` to persist killfile entries.

## Configuration

All configuration is done using commands.

## Commands

    hubot killfile (on|off) - Activate/deactivate killfile.
    hubot killfile show - Print the list of patterns to exclude.
    hubot killfile add <pattern> - Add killfile entry
    hubot killfile remove <N> - Delete killfile entry (by index)
