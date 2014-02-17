realize = require './realize'
util = require './util'
factories = require './factory'

container =
    instances: util.merge(util, {
        Promise: require('bluebird')
        EventEmitter: require('events').EventEmitter
    })
    factories: factories

realize container

module.exports = container.instances
