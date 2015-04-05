Promise = require 'bluebird'

hinoki = require '../src/hinoki'

factories =
  count: (xs) ->
    Promise.delay(xs.length, 100)
  mean: (xs, count) ->
    reducer = (acc, x) ->
      acc + x
    Promise.delay(xs.reduce(reducer, 0) / count, 100)
  meanOfSquares: (xs, count) ->
    reducer = (acc, x) ->
      acc + x * x
    Promise.delay(xs.reduce(reducer, 0) / count, 100)
  variance: (mean, meanOfSquares) ->
    Promise.delay(meanOfSquares - mean * mean, 100)

module.exports =

  'ask for count': (test) ->
    lifetime =
      factories: factories
      values:
        xs: [1, 2, 3, 6]

    hinoki(lifetime, 'count').then (count) ->
      test.equal count, 4
      test.deepEqual lifetime.values,
        xs: [1, 2, 3, 6]
        count: 4
      test.done()

  'ask for mean': (test) ->
    lifetime =
      factories: factories
      values:
        xs: [1, 2, 3, 6]

    hinoki(lifetime, 'mean').then (mean) ->
      test.equal mean, 3
      test.deepEqual lifetime.values,
        xs: [1, 2, 3, 6]
        count: 4
        mean: 3
      test.done()

  'ask for meanOfSquares': (test) ->
    lifetime =
      factories: factories
      values:
        xs: [1, 2, 3, 6]

    hinoki(lifetime, 'meanOfSquares').then (meanOfSquares) ->
      test.equal meanOfSquares, 12.5
      test.deepEqual lifetime.values,
        xs: [1, 2, 3, 6]
        count: 4
        meanOfSquares: 12.5
      test.done()

  'ask for variance': (test) ->
    lifetime =
      factories: factories
      values:
        xs: [1, 2, 3, 6]

    hinoki(lifetime, 'variance').then (variance) ->
      test.equal variance, 3.5
      test.deepEqual lifetime.values,
        xs: [1, 2, 3, 6]
        count: 4
        mean: 3
        meanOfSquares: 12.5
        variance: 3.5
      test.done()
