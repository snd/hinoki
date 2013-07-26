hinoki = require '../src/hinoki'

module.exports =

    'not a function': (test) ->
        try
            hinoki.parseFunctionArguments 0
        catch err
            test.equals err.message, 'argument must be a function'

        try
            hinoki.parseFunctionArguments {}
        catch err
            test.equals err.message, 'argument must be a function'

        try
            hinoki.parseFunctionArguments 'a'
        catch err
            test.equals err.message, 'argument must be a function'

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
