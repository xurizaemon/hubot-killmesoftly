# Hubot killfile / spam filter.

A pattern-based community killfile for outgoing Hubot messages. Implements a middleware to intercept messages Hubot is about to post, refrains from outputting matched messages.

Perhaps you'd like to prevent Hubot being trained to swear, or you use [hubot-twitter-mention](https://github.com/vspiewak/hubot-twitter-mention) but you want to filter out some returned Tweets.

Uses `robot.brain` to persist killfile entries.

## Configuration

All configuration is done using commands as below.

## Commands

    hubot refrain (on|off) - Activate/deactivate refrain filter.
    hubot refrain show - Print the list of patterns to refrain from saying.
    hubot refrain add <pattern> - Add refrain filter entry
    hubot refrain remove <N> - Delete refrain filter entry (by index)
