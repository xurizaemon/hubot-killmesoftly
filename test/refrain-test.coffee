Helper = require 'hubot-test-helper'
chai = require 'chai'
chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'
helper = new Helper('../src/refrain.coffee')
expect = chai.expect

describe 'killmesoftly', ->
  room = null

  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()
    room = helper.createRoom()

  afterEach ->
    room.destroy()

  it 'registers some respond listeners', ->
    expect(@robot.respond).to.have.been.calledWith(/killfile show/)
    expect(@robot.respond).to.have.been.calledWith(/killfile add (.*)/)
    expect(@robot.respond).to.have.been.calledWith(/killfile remove (.*)/)
    expect(@robot.respond).to.have.been.calledWith(/killfile (on|off)/)
