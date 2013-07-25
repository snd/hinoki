q = require 'q'

hinoki = require '../src/hinoki'

computationExampleFactories =
    count: (xs) ->
        xs.length
    mean: (xs, count) ->
        reducer = (acc, x) ->
            acc + x
        xs.reduce(reducer, 0) / count
    meanOfSquares: (xs, count) ->
        reducer = (acc, x) ->
            acc + x * x
        xs.reduce(reducer, 0) / count
    variance: (mean, meanOfSquares) ->
        meanOfSquares - mean * mean

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

    'find with 1 container':

        'not found': (test) ->
            result = hinoki.find [{}], 'id'
            test.ok not result?
            test.done()

        'instance found': (test) ->
            c =
                scope:
                    a: 5

            result = hinoki.find [c], 'a'

            test.equal result.instance, 5
            test.equal result.containers.length, 1
            test.equal result.containers[0], c

            test.done()

        'factory found': (test) ->
            c =
                scope: {}
                factories:
                    a: 5

            result = hinoki.find [c], 'a'

            test.equal result.factory, 5
            test.equal result.containers.length, 1
            test.equal result.containers[0], c

            test.done()

    'find with 3 containers':

        'not found': (test) ->
            result = hinoki.find [{}, {}, {}], 'id'
            test.ok not result?
            test.done()

        'instance found in 1st container': (test) ->
            c1 =
                scope:
                    a: 5
            c2 = {}
            c3 = {}

            result = hinoki.find [c1, c2, c3], 'a'

            test.equal result.instance, 5
            test.equal result.containers.length, 3
            test.equal result.containers[0], c1
            test.equal result.containers[1], c2
            test.equal result.containers[2], c3

            test.done()

        'instance found in 2nd container': (test) ->
            c1 = {}
            c2 =
                scope:
                    a: 5
            c3 = {}

            result = hinoki.find [c1, c2, c3], 'a'

            test.equal result.instance, 5
            test.equal result.containers.length, 2
            test.equal result.containers[0], c2
            test.equal result.containers[1], c3

            test.done()

        'instance found in 3rd container': (test) ->
            c1 = {}
            c2 = {}
            c3 =
                scope:
                    a: 5

            result = hinoki.find [c1, c2, c3], 'a'

            test.equal result.instance, 5
            test.equal result.containers.length, 1
            test.equal result.containers[0], c3

            test.done()

        'factory found in 1st container': (test) ->
            c1 =
                factories:
                    a: 5
            c2 = {}
            c3 = {}

            result = hinoki.find [c1, c2, c3], 'a'

            test.equal result.factory, 5
            test.equal result.containers.length, 3
            test.equal result.containers[0], c1
            test.equal result.containers[1], c2
            test.equal result.containers[2], c3

            test.done()

        'factory found in 2nd container': (test) ->
            c1 = {}
            c2 =
                factories:
                    a: 5
            c3 = {}

            result = hinoki.find [c1, c2, c3], 'a'

            test.equal result.factory, 5
            test.equal result.containers.length, 2
            test.equal result.containers[0], c2
            test.equal result.containers[1], c3

            test.done()

        'factory found in 3rd container': (test) ->
            c1 = {}
            c2 = {}
            c3 =
                factories:
                    a: 5

            result = hinoki.find [c1, c2, c3], 'a'

            test.equal result.factory, 5
            test.equal result.containers.length, 1
            test.equal result.containers[0], c3

            test.done()

    'inject with 1 container':

        'missing factory': (test) ->
            try
                hinoki.inject {}, (a) ->
            catch error
                test.equals error.message, "missing factory for service 'a'"
                test.done()

        'one factory': (test) ->
            container =
                factories:
                    a: -> 5

            hinoki.inject container, (a) ->
                test.equals a, 5
                test.deepEqual container.scope,
                    a: 5
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

        '1 seed': (test) ->
            container =
                scope:
                    a: 5

            hinoki.inject container, (a) ->
                test.equals a, 5
                test.done()

        '3 dependencies': (test) ->
            container =
                factories:
                    a: -> 1
                    b: (a) -> a + 1
                    c: (a, b) -> a + b + 1

            hinoki.inject container, (a, b, c) ->
                test.equals a, 1
                test.equals b, 2
                test.equals c, 4
                test.deepEqual container.scope,
                    a: 1
                    b: 2
                    c: 4
                test.done()

        '1 factory and 2 seeds': (test) ->
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
                test.deepEqual container.scope,
                    a: 1
                    b: 2
                    c: 4
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
                test.deepEqual container.scope, {}
                test.done()

        'self dependency': (test) ->
            container =
                factories:
                    a: (a) ->

            try
                hinoki.inject container, (a) ->
            catch error
                test.equals error.message, "circular dependency a <- a"
                test.deepEqual container.scope, {}
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
                test.deepEqual container.scope, {}
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
                test.deepEqual container.scope,
                    a: 5
                test.done()

        'one async dependency with error': (test) ->
            container =
                factories:
                    a: ->
                        deferred = q.defer()
                        q.nextTick ->
                            deferred.reject 5
                        return deferred.promise

            q.onerror = (err) ->
                test.equals err.message, "error resolving promise returned from factory 'a'"
                test.deepEqual container.scope, {}
                test.done()

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
                test.deepEqual container.scope,
                    a: 1
                    b: 2
                    c: 4
                test.done()

    'containers can depend on services in containers to the right of them': (test) ->
        container1 =
            factories:
                b: (a) ->
                    a + 1

        container2 =
            factories:
                a: -> 1

        hinoki.inject [container1, container2], (b) ->
            test.equals b, 2
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
            test.equals err.message, "missing factory for service 'a'"
            test.done()

    'inject with 3 containers':

        '3 async dependencies': (test) ->
            container1 =
                factories:
                    c: (a, b) ->
                        deferred = q.defer()
                        q.nextTick -> deferred.resolve a + b + 1
                        return deferred.promise

            container2 =
                factories:
                    b: (a) ->
                        deferred = q.defer()
                        q.nextTick -> deferred.resolve a + 1
                        return deferred.promise

            container3 =
                factories:
                    a: ->
                        deferred = q.defer()
                        q.nextTick -> deferred.resolve 1
                        return deferred.promise

            hinoki.inject [container1, container2, container3], (a, b, c) ->
                test.equals a, 1
                test.equals b, 2
                test.equals c, 4
                test.deepEqual container1.scope,
                    c: 4
                test.deepEqual container2.scope,
                    b: 2
                test.deepEqual container3.scope,
                    a: 1
                test.done()

    'examples':

        'computation - ask for count': (test) ->
            c =
                factories: computationExampleFactories
                scope:
                    xs: [1, 2, 3, 6]

            hinoki.inject c, (count) ->
                test.equals count, 4
                test.deepEqual c.scope,
                    xs: [1, 2, 3, 6]
                    count: 4
                test.done()

        'computation - ask for mean': (test) ->
            c =
                factories: computationExampleFactories
                scope:
                    xs: [1, 2, 3, 6]

            hinoki.inject c, (mean) ->
                test.equals mean, 3
                test.deepEqual c.scope,
                    xs: [1, 2, 3, 6]
                    count: 4
                    mean: 3
                test.done()

        'computation - ask for meanOfSquares': (test) ->
            c =
                factories: computationExampleFactories
                scope:
                    xs: [1, 2, 3, 6]

            hinoki.inject c, (meanOfSquares) ->
                test.equals meanOfSquares, 12.5
                test.deepEqual c.scope,
                    xs: [1, 2, 3, 6]
                    count: 4
                    meanOfSquares: 12.5
                test.done()

        'computation - ask for variance': (test) ->
            c =
                factories: computationExampleFactories
                scope:
                    xs: [1, 2, 3, 6]

            hinoki.inject c, (variance) ->
                test.equals variance, 3.5
                test.deepEqual c.scope,
                    xs: [1, 2, 3, 6]
                    count: 4
                    mean: 3
                    meanOfSquares: 12.5
                    variance: 3.5
                test.done()
