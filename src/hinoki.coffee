core = require './core'
ioc = require './ioc'

module.exports = hinoki = core

# manual dependency injection
# ---------------------------

assembleReturningPromise = ->
    hinoki.assembleReturningPromise.call null, arguments

hinoki.requireReturningPromise =
    ioc.requireReturningPromise hinoki.find,
        assembleReturningPromise

hinoki.assembleReturningPromise =
    ioc.assembleReturningPromise core.parseFunctionArguments,
        hinoki.requireReturningPromise,
        core.callFactoryReturningPromise

hinoki.inject =
    ioc.inject hinoki.requireReturningPromise, hinoki.reasonToError
