Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

    'cycle': (test) ->
        test.expect 3

        c = hinoki.newContainer
            a: (a) ->

        c.emitter.on 'error', (error) ->
            test.equals error.type, 'cycle'
            test.deepEqual error.id, ['a', 'a']
            test.equals error.container, c
            test.done()

        hinoki.inject c, (a) ->
            test.fail()

    'unresolvableFactory': (test) ->
        test.expect 3

        c = hinoki.newContainer()

        c.emitter.on 'error', (error) ->
            test.equals error.type, 'unresolvableFactory'
            test.deepEqual error.id, 'a'
            test.equals error.container, c
            test.done()

        hinoki.inject c, (a) ->
            test.fail()

    'exception': (test) ->
        test.expect 4

        exception = {}

        c = hinoki.newContainer
            a: -> throw exception

        c.emitter.on 'error', (error) ->
            test.equals error.type, 'exception'
            test.equals error.id, 'a'
            test.equals error.container, c
            test.equals error.exception, exception
            test.done()

        hinoki.inject c, (a) ->
            test.fail()

    'rejection': (test) ->
        test.expect 4

        rejection = {}

        c = hinoki.newContainer
            a: -> Promise.reject rejection

        c.emitter.on 'error', (error) ->
            test.equals error.type, 'rejection'
            test.equals error.id, 'a'
            test.equals error.container, c
            test.equals error.rejection, rejection
            test.done()

        hinoki.inject c, (a) ->
            test.fail()

    'factoryNotFunction': (test) ->
        test.expect 4

        factory = {}

        c = hinoki.newContainer
            a: factory

        c.emitter.on 'error', (error) ->
            test.equals error.type, 'factoryNotFunction'
            test.equals error.id, 'a'
            test.equals error.container, c
            test.equals error.factory, factory
            test.done()

        hinoki.inject c, (a) ->
            test.fail()

    'factoryReturnedUndefined': (test) ->
        test.expect 3

        c = hinoki.newContainer
            a: ->

        c.emitter.on 'error', (error) ->
            test.equals error.type, 'factoryReturnedUndefined'
            test.equals error.id, 'a'
            test.equals error.container, c
            test.done()

        hinoki.inject c, (a) ->
            test.fail()
