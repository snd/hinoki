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

            block = ->
                hinoki.inject container, (a) ->

            test.throws block, Error, "missing factory for service 'a'"
            test.done()

        'one factory': (test) ->
            container =
                factories:
                    a: -> 5

            hinoki.inject container, (a) ->
                test.equals a, 5
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
                    a: (c) -> 1
                    b: (a) -> a + 1
                    c: (a, b) -> a + b + 1

            block = ->
                hinoki.inject container, (a) ->
            test.throws block, Error, "circular dependency a <- c <- a"
            test.done()
