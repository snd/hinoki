hinoki = require '../src/hinoki'

module.exports =

    'not found': (test) ->
        result = hinoki.find [{}, {}, {}], 'id'
        test.ok not result?
        test.done()

    'instance found in 1st container': (test) ->
        c1 =
            instances:
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
            instances:
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
            instances:
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

