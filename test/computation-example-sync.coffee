hinoki = require '../src/hinoki'

factories =
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

  'ask for count': (test) ->
    source = hinoki.source factories
    lifetime =
      xs: [1, 2, 3, 6]

    hinoki(source, lifetime, 'count')
      .then (count) ->
        test.equal count, 4
        test.deepEqual lifetime,
          xs: [1, 2, 3, 6]
          count: 4
        test.done()

  'ask for mean': (test) ->
    source = hinoki.source factories
    lifetime =
      xs: [1, 2, 3, 6]

    hinoki(source, lifetime, 'mean').then (mean) ->
      test.equal mean, 3
      test.deepEqual lifetime,
        xs: [1, 2, 3, 6]
        count: 4
        mean: 3
      test.done()

  'ask for meanOfSquares': (test) ->
    source = hinoki.source factories
    lifetime =
      xs: [1, 2, 3, 6]

    hinoki(source, lifetime, 'meanOfSquares').then (meanOfSquares) ->
      test.equal meanOfSquares, 12.5
      test.deepEqual lifetime,
        xs: [1, 2, 3, 6]
        count: 4
        meanOfSquares: 12.5
      test.done()

  'ask for variance': (test) ->
    source = hinoki.source factories
    lifetime =
      xs: [1, 2, 3, 6]

    hinoki(source, lifetime, 'variance').then (variance) ->
      test.equal variance, 3.5
      test.deepEqual lifetime,
        xs: [1, 2, 3, 6]
        count: 4
        mean: 3
        meanOfSquares: 12.5
        variance: 3.5
      test.done()
