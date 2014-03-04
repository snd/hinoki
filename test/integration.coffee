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

    'sync computation example':

        'ask for count': (test) ->
            c = hinoki.newContainer computationExampleFactories,
                xs: [1, 2, 3, 6]

            hinoki.inject c, (count) ->
                test.equals count, 4
                test.deepEqual c.instances,
                    xs: [1, 2, 3, 6]
                    count: 4
                test.done()

        'ask for mean': (test) ->
            c = hinoki.newContainer computationExampleFactories,
                xs: [1, 2, 3, 6]

            hinoki.inject c, (mean) ->
                test.equals mean, 3
                test.deepEqual c.instances,
                    xs: [1, 2, 3, 6]
                    count: 4
                    mean: 3
                test.done()

        'ask for meanOfSquares': (test) ->
            c = hinoki.newContainer computationExampleFactories,
                xs: [1, 2, 3, 6]

            hinoki.inject c, (meanOfSquares) ->
                test.equals meanOfSquares, 12.5
                test.deepEqual c.instances,
                    xs: [1, 2, 3, 6]
                    count: 4
                    meanOfSquares: 12.5
                test.done()

        'ask for variance': (test) ->
            c = hinoki.newContainer computationExampleFactories,
                xs: [1, 2, 3, 6]

            hinoki.inject c, (variance) ->
                test.equals variance, 3.5
                test.deepEqual c.instances,
                    xs: [1, 2, 3, 6]
                    count: 4
                    mean: 3
                    meanOfSquares: 12.5
                    variance: 3.5
                test.done()

#     'async':
#
#
    'error':

        'cycle': (test) ->
            test.expect 3

            c = hinoki.newContainer
                a: (a) ->

            c.emitter.on 'error', (error) ->
                test.equals error.type, 'cycle'
                test.deepEqual error.id, ['a', 'a']
                test.equals error.container, c
                test.done()

            hinoki.inject c, (a) ->
                test.fail()

        'unresolvableFactoryRejection': (test) ->
            test.expect 3

            c = hinoki.newContainer()

            c.emitter.on 'error', (error) ->
                test.equals error.type, 'unresolvableFactory'
                test.deepEqual error.id, 'a'
                test.equals error.container, c
                test.done()

            hinoki.inject c, (a) ->
                test.fail()

        'exceptionRejection': (test) ->
            test.expect 3

            exception = {}

            c = hinoki.newContainer
                a: -> throw exception

            c.emitter.on 'error', (error) ->
                test.equals error.type, 'exceptionRejection'
                test.deepEqual error.id, 'a'
                test.equals error.container, c
                test.done()

            hinoki.inject c, (a) ->
                test.fail()
