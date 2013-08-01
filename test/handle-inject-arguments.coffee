hinoki = require '../src/hinoki'

module.exports =

    'error':

        '1st argument must be an object or array': (test) ->
            try
                hinoki.handleInjectArguments 5
            catch err
                test.equals err.message, 'the 1st argument to inject must be an object or an array of objects'

            try
                hinoki.handleInjectArguments [5]
            catch err
                test.equals err.message, 'the 1st argument to inject must be an object or an array of objects'

            test.done()

        '2nd argument must be a function': (test) ->
            try
                hinoki.handleInjectArguments {}, 5
            catch err
                test.equals err.message, 'the 2nd argument to inject must be a function if no 3rd argument is provided'

            test.done()

        '3rd argument must be a function': (test) ->
            try
                hinoki.handleInjectArguments {}, 'a', 5
            catch err
                test.equals err.message, 'the 3rd argument to inject is optional but must be a function if provided'

            test.done()

        '2nd argument must be a string or array': (test) ->
            try
                hinoki.handleInjectArguments {}, 5, ->
            catch err
                test.equals err.message, 'the 2nd argument to inject must be a string or an array of strings if a 3rd argument is provided'

            test.done()

    'parse from function':

        '1 container, 0 ids': (test) ->
            c1 = {}
            fun = ->

            args = hinoki.handleInjectArguments c1, fun

            test.equals args.containers.length, 1
            test.equals args.containers[0], c1

            test.deepEqual args.ids, []
            test.equals args.fun, fun

            test.done()

        '1 container, 1 ids': (test) ->
            c1 = {}
            fun = (a) ->

            args = hinoki.handleInjectArguments c1, fun

            test.equals args.containers.length, 1
            test.equals args.containers[0], c1

            test.deepEqual args.ids, ['a']
            test.equals args.fun, fun

            test.done()

        '1 container, 3 ids': (test) ->
            c1 = {}
            fun = (a, b, c) ->

            args = hinoki.handleInjectArguments c1, fun

            test.equals args.containers.length, 1
            test.equals args.containers[0], c1

            test.deepEqual args.ids, ['a', 'b', 'c']
            test.equals args.fun, fun

            test.done()

        '3 container, 1 id': (test) ->
            c1 = {}
            c2 = {}
            c3 = {}
            fun = (a) ->

            args = hinoki.handleInjectArguments [c1, c2, c3], fun

            test.equals args.containers.length, 3
            test.equals args.containers[0], c1
            test.equals args.containers[1], c2
            test.equals args.containers[2], c3

            test.deepEqual args.ids, ['a']
            test.equals args.fun, fun

            test.done()

    'explicit ids':

        '1 container, 0 ids': (test) ->
            c1 = {}
            fun = ->

            args = hinoki.handleInjectArguments c1, [], fun

            test.equals args.containers.length, 1
            test.equals args.containers[0], c1

            test.deepEqual args.ids, []
            test.equals args.fun, fun

            test.done()

        '1 container, 1 id as string': (test) ->
            c1 = {}
            fun = ->

            args = hinoki.handleInjectArguments c1, 'a', fun

            test.equals args.containers.length, 1
            test.equals args.containers[0], c1

            test.deepEqual args.ids, ['a']
            test.equals args.fun, fun

            test.done()

        '1 container, 1 id as array': (test) ->
            c1 = {}
            fun = ->

            args = hinoki.handleInjectArguments c1, ['a'], fun

            test.equals args.containers.length, 1
            test.equals args.containers[0], c1

            test.deepEqual args.ids, ['a']
            test.equals args.fun, fun

            test.done()

        '1 container, 3 ids': (test) ->
            c1 = {}
            fun = ->

            args = hinoki.handleInjectArguments c1, ['a', 'b', 'c'], fun

            test.equals args.containers.length, 1
            test.equals args.containers[0], c1

            test.deepEqual args.ids, ['a', 'b', 'c']
            test.equals args.fun, fun

            test.done()

        '3 container, 1 id as array': (test) ->
            c1 = {}
            c2 = {}
            c3 = {}
            fun = (a) ->

            args = hinoki.handleInjectArguments [c1, c2, c3], ['a'], fun

            test.equals args.containers.length, 3
            test.equals args.containers[0], c1
            test.equals args.containers[1], c2
            test.equals args.containers[2], c3

            test.deepEqual args.ids, ['a']
            test.equals args.fun, fun

            test.done()
