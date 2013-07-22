hinoki = require '../src/hinoki'

module.exports =

    'parseDependencies':

        'not a function': (test) ->
            test.throws ->
                hinoki.parseDependencies 0
            test.throws ->
                hinoki.parseDependencies {}
            test.throws ->
                hinoki.parseDependencies 'a'
            test.done()

        '0 dependencies': (test) ->
            test.deepEqual [], hinoki.parseDependencies ->
            test.done()

        '1 dependency': (test) ->
            test.deepEqual ['first'],
                hinoki.parseDependencies (first) ->
            test.done()

        '2 dependencies': (test) ->
            test.deepEqual ['first', 'second'],
                hinoki.parseDependencies (first, second) ->
            test.done()

        '3 dependencies': (test) ->
            test.deepEqual ['first', 'second', 'third'],
                hinoki.parseDependencies (first, second, third) ->
            test.done()
