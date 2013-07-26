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

    'factoryFound': (test) ->
        test.expect 4
        f = (b, c) -> b + c + 3
        container =
            factories:
                a: f
            instances:
                b: 1
                c: 2
            hooks:
                factoryFound: (chain, factory, dependencyIds) ->
                    test.deepEqual chain, ['a']
                    test.equals factory, f
                    test.deepEqual dependencyIds, ['b', 'c']

        hinoki.inject container, (a) ->
            test.equals a, 6
            test.done()

    'instance': (test) ->
        test.expect 3

        container =
            factories:
                a: -> 5
            hooks:
                instance: (chain, instance) ->
                    test.deepEqual chain, ['a']
                    test.equals instance, 5

        hinoki.inject container, (a) ->
            test.equals a, 5
            test.done()

    'promise': (test) ->
        test.expect 3

        promiseObject = null

        container =
            factories:
                a: ->
                    deferred = q.defer()
                    q.nextTick -> deferred.resolve 5
                    promiseObject = deferred.promise
                    return deferred.promise
            hooks:
                promise: (chain, promise) ->
                    test.deepEqual chain, ['a']
                    test.equals promise, promiseObject

        hinoki.inject container, (a) ->
            test.equals a, 5
            test.done()

    'resolution': (test) ->
        test.expect 3

        container =
            factories:
                a: ->
                    deferred = q.defer()
                    q.nextTick -> deferred.resolve 5
                    return deferred.promise
            hooks:
                resolution: (chain, instance) ->
                    test.deepEqual chain, ['a']
                    test.equals instance, 5

        hinoki.inject container, (a) ->
            test.equals a, 5
            test.done()

    'factory': (test) ->
        test.expect 4

        f = (b, c) -> b + c

        container =
            factories:
                a: f
            instances:
                b: 2
                c: 1
            hooks:
                factory: (chain, factory, args) ->
                    test.deepEqual chain, ['a']
                    test.equals factory, f
                    test.deepEqual args, [2, 1]

        hinoki.inject container, (a) ->
            test.equals a, 3
            test.done()
