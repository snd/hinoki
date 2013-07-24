q = require 'q'

hinoki = require '../src/hinoki'

module.exports =

    'parseFunctionArguments':

        'not a function': (test) ->
            test.throws ->
                hinoki.parseFunctionArguments 0
            test.throws ->
                hinoki.parseFunctionArguments {}
            test.throws ->
                hinoki.parseFunctionArguments 'a'
            test.done()

        '0 dependencies': (test) ->
            test.deepEqual [], hinoki.parseFunctionArguments ->
            test.done()

        '1 dependency': (test) ->
            test.deepEqual ['first'],
                hinoki.parseFunctionArguments (first) ->
            test.done()

        '2 dependencies': (test) ->
            test.deepEqual ['first', 'second'],
                hinoki.parseFunctionArguments (first, second) ->
            test.done()

        '3 dependencies': (test) ->
            test.deepEqual ['first', 'second', 'third'],
                hinoki.parseFunctionArguments (first, second, third) ->
            test.done()

    'inject':

        'missing factory': (test) ->
            container = {}

            try
                hinoki.inject container, (a) ->
            catch error
                test.equals error.message, "missing factory for service 'a'"
                test.done()

        'one factory': (test) ->
            container =
                factories:
                    a: -> 5

            hinoki.inject container, (a) ->
                test.equals a, 5
                test.done()

        'exception in factory': (test) ->
            container =
                factories:
                    a: ->
                        throw new Error 'b'

            try
                hinoki.inject container, (a) ->
            catch error
                test.equals error.message, "exception in factory 'a': Error: b"
                test.done()

        'one seed': (test) ->
            container =
                scope:
                    a: 5

            hinoki.inject container, (a) ->
                test.equals a, 5
                test.done()

        'three dependencies': (test) ->
            container =
                factories:
                    a: -> 1
                    b: (a) -> a + 1
                    c: (a, b) -> a + b + 1

            hinoki.inject container, (a, b, c) ->
                test.equals a, 1
                test.equals b, 2
                test.equals c, 4
                test.done()

        'one factory and two seeds': (test) ->
            container =
                scope:
                    a: 1
                    b: 2
                factories:
                    c: (a, b) -> a + b + 1

            hinoki.inject container, (a, b, c) ->
                test.equals a, 1
                test.equals b, 2
                test.equals c, 4
                test.done()

        'circular dependency': (test) ->
            container =
                factories:
                    a: (c) ->
                    b: (a) ->
                    c: (a, b) ->

            try
                hinoki.inject container, (a) ->
            catch error
                test.equals error.message, "circular dependency a <- c <- a"
                test.done()

        'self dependency': (test) ->
            container =
                factories:
                    a: (a) ->

            try
                hinoki.inject container, (a) ->
            catch error
                test.equals error.message, "circular dependency a <- a"
                test.done()

        'long circular dependency': (test) ->
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
                test.equals error.message, "circular dependency a <- b <- c <- d <- e <- f <- a"
                test.done()

        'one async dependency with success': (test) ->
            container =
                factories:
                    a: ->
                        deferred = q.defer()
                        q.nextTick ->
                            deferred.resolve 5
                        return deferred.promise

            hinoki.inject container, (a) ->
                test.equals a, 5
                test.done()

        'one async dependency with error': (test) ->
            q.onerror = (err) ->
                test.equals err.message, "error resolving promise returned from factory 'a'"
                test.done()

            container =
                factories:
                    a: ->
                        deferred = q.defer()
                        q.nextTick ->
                            deferred.reject 5
                        return deferred.promise

            hinoki.inject container, (a) ->

        '3 async dependencies': (test) ->
            container =
                factories:
                    a: ->
                        deferred = q.defer()
                        q.nextTick -> deferred.resolve 1
                        return deferred.promise
                    b: (a) ->
                        deferred = q.defer()
                        q.nextTick -> deferred.resolve a + 1
                        return deferred.promise
                    c: (a, b) ->
                        deferred = q.defer()
                        q.nextTick -> deferred.resolve a + b + 1
                        return deferred.promise

            hinoki.inject container, (a, b, c) ->
                test.equals a, 1
                test.equals b, 2
                test.equals c, 4
                test.done()
