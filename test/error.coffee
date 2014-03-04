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

    'unresolvableFactoryRejection': (test) ->
        test.expect 3

        c = hinoki.newContainer()

        c.emitter.on 'error', (error) ->
            test.equals error.type, 'unresolvableFactory'
            test.deepEqual error.id, 'a'
            test.equals error.container, c
            test.done()

        hinoki.inject c, (a) ->
            test.fail()

    'exceptionRejection': (test) ->
        test.expect 3

        exception = {}

        c = hinoki.newContainer
            a: -> throw exception

        c.emitter.on 'error', (error) ->
            test.equals error.type, 'exceptionRejection'
            test.deepEqual error.id, 'a'
            test.equals error.container, c
            test.done()

        hinoki.inject c, (a) ->
            test.fail()
