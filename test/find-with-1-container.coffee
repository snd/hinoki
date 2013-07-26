hinoki = require '../src/hinoki'

module.exports =

    'not found': (test) ->
        result = hinoki.find [{}], 'id'
        test.ok not result?
        test.done()

    'instance found': (test) ->
        c =
            instances:
                a: 5

        result = hinoki.find [c], 'a'

        test.equal result.instance, 5
        test.equal result.containers.length, 1
        test.equal result.containers[0], c

        test.done()

    'factory found': (test) ->
        c =
            instances: {}
            factories:
                a: 5

        result = hinoki.find [c], 'a'

        test.equal result.factory, 5
        test.equal result.containers.length, 1
        test.equal result.containers[0], c

        test.done()
