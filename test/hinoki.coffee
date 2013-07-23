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

        'single factory': (test) ->
            container =
                factories:
                    a: -> 5

            hinoki.inject container, (a) ->
                test.equals a, 5
                test.done()

        'no factory but in scope': (test) ->
            container =
                scope:
                    a: 5

            hinoki.inject container, (a) ->
                test.equals a, 5
                test.done()
