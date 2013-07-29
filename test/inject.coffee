q = require 'q'

hinoki = require '../src/hinoki'

module.exports =

    '1 container':

        'one factory': (test) ->
            container =
                factories:
                    a: -> 5

            hinoki.inject container, (a) ->
                test.equals a, 5
                test.deepEqual container.instances,
                    a: 5
                test.done()

        '1 seed': (test) ->
            container =
                instances:
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
                test.deepEqual container.instances,
                    a: 1
                    b: 2
                    c: 4
                test.done()

        '3 dependencies - ask for nothing': (test) ->
            container =
                factories:
                    a: -> 1
                    b: (a) -> a + 1
                    c: (a, b) -> a + b + 1

            hinoki.inject container, ->
                test.deepEqual container.instances, {}
                test.done()

        '1 factory and 2 seeds': (test) ->
            container =
                instances:
                    a: 1
                    b: 2
                factories:
                    c: (a, b) -> a + b + 1

            hinoki.inject container, (a, b, c) ->
                test.equals a, 1
                test.equals b, 2
                test.equals c, 4
                test.deepEqual container.instances,
                    a: 1
                    b: 2
                    c: 4
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
                test.deepEqual container.instances,
                    a: 5
                test.done()

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
                test.deepEqual container.instances,
                    a: 1
                    b: 2
                    c: 4
                test.done()

    '2 containers':

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

    '3 containers':

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
                test.deepEqual container1.instances,
                    c: 4
                test.deepEqual container2.instances,
                    b: 2
                test.deepEqual container3.instances,
                    a: 1
                test.done()
