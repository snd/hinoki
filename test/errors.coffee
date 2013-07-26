q = require 'q'

hinoki = require '../src/hinoki'

module.exports =

    'exception': (test) ->
        container =
            factories:
                a: ->
                    throw new Error 'b'

        try
            hinoki.inject container, (a) ->
        catch error
            test.equals error.message, "exception in factory 'a': Error: b"
            test.done()

    'not a function': (test) ->
        container =
            factories:
                a: 5

        try
            hinoki.inject container, (a) ->
        catch error
            test.equals error.message, "factory 'a' is not a function: 5"
            test.done()

    'circle': (test) ->
        container =
            factories:
                a: (c) ->
                b: (a) ->
                c: (a, b) ->

        try
            hinoki.inject container, (a) ->
        catch error
            test.equals error.message, "circular dependency a <- c <- a"
            test.deepEqual container.instances, {}
            test.done()

    'circle (self)': (test) ->
        container =
            factories:
                a: (a) ->

        try
            hinoki.inject container, (a) ->
        catch error
            test.equals error.message, "circular dependency a <- a"
            test.deepEqual container.instances, {}
            test.done()

    'circle (long)': (test) ->
        container =
            factories:
                a: (b) ->
                b: (c) ->
                c: (d) ->
                d: (e) ->
                e: (f) ->
                f: (a) ->

        try
            hinoki.inject container, (a) ->
        catch error
            test.equals error.message, "circular dependency a <- f <- e <- d <- c <- b <- a"
            test.deepEqual container.instances, {}
            test.done()

    'rejection': (test) ->
        container =
            factories:
                a: ->
                    deferred = q.defer()
                    q.nextTick ->
                        deferred.reject 5
                    return deferred.promise

        q.onerror = (err) ->
            test.equals err.message, "promise returned from factory 'a' was rejected with: 5"
            test.deepEqual container.instances, {}
            test.done()

        hinoki.inject container, (a) ->

    'not found': (test) ->
        try
            hinoki.inject {}, (a) ->
        catch error
            test.equals error.message, "missing factory 'a' (a)"
            test.done()

    'containers can not depend on services in containers to the left of them': (test) ->
            container1 =
                factories:
                    a: -> 1

            container2 =
                factories:
                    b: (a) ->
                        a + 1

            try
                hinoki.inject [container1, container2], (b) ->
            catch err
                test.equals err.message, "missing factory 'a' (a <- b)"
                test.done()
