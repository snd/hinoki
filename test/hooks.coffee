q = require 'q'

hinoki = require '../src/hinoki'

module.exports =

    'not found': (test) ->
        c =
            factories:
                a: (b) ->
            hooks:
                notFound: (chain) ->
                    test.deepEqual chain, ['b', 'a']
                    test.done()
        hinoki.inject c, (a) ->
            test.fail()

    'exception': (test) ->
        container =
            factories:
                a: (b) ->
                b: ->
                    throw new Error 'error'
            hooks:
                exception: (chain, err) ->
                    test.deepEqual chain, ['b', 'a']
                    test.equals err.message, 'error'
                    test.done()

        hinoki.inject container, (a) ->
            test.fail()

    'not a function': (test) ->
        container =
            factories:
                a: (b) ->
                b: 5
            hooks:
                notFunction: (chain, factory) ->
                    test.deepEqual chain, ['b', 'a']
                    test.equals factory, 5
                    test.done()

        hinoki.inject container, (a) ->
            test.fail()

    'circle': (test) ->
        container =
            factories:
                a: (c) ->
                b: (a) ->
                c: (a, b) ->
            hooks:
                circle: (chain) ->
                    test.deepEqual chain, ['a', 'c', 'a']
                    test.done()

        hinoki.inject container, (a) ->
            test.fail()

    'circle (self)': (test) ->
        container =
            factories:
                a: (a) ->
            hooks:
                circle: (chain) ->
                    test.deepEqual chain, ['a', 'a']
                    test.done()

        hinoki.inject container, (a) ->
            test.fail()

    'circle (long)': (test) ->
        container =
            factories:
                a: (b) ->
                b: (c) ->
                c: (d) ->
                d: (e) ->
                e: (f) ->
                f: (a) ->
            hooks:
                circle: (chain) ->
                    test.deepEqual chain, ['a', 'f', 'e', 'd', 'c', 'b', 'a']
                    test.done()

        hinoki.inject container, (a) ->
            test.fail()

    'rejection': (test) ->
        container =
            factories:
                a: (b) ->
                b: ->
                    deferred = q.defer()
                    q.nextTick ->
                        deferred.reject 5
                    return deferred.promise
            hooks:
                rejection: (chain, err) ->
                    test.deepEqual chain, ['b', 'a']
                    test.equals err, 5
                    test.done()

        hinoki.inject container, (a) ->
            test.fail()

    'instanceFound': (test) ->
        test.expect 3
        container =
            factories:
                a: (b) -> b + 3
            instances:
                b: 5
            hooks:
                instanceFound: (chain, instance) ->
                    test.deepEqual chain, ['b', 'a']
                    test.equals instance, 5

        hinoki.inject container, (a) ->
            test.equals a, 8
            test.done()
