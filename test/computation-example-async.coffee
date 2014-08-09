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
    c =
      factories: factories
      values:
        xs: [1, 2, 3, 6]

    hinoki.get(c, 'count').then (count) ->
      test.equals count, 4
      test.deepEqual c.values,
        xs: [1, 2, 3, 6]
        count: 4
      test.done()

  'ask for mean': (test) ->
    c =
      factories: factories
      values:
        xs: [1, 2, 3, 6]

    hinoki.get(c, 'mean').then (mean) ->
      test.equals mean, 3
      test.deepEqual c.values,
        xs: [1, 2, 3, 6]
        count: 4
        mean: 3
      test.done()

  'ask for meanOfSquares': (test) ->
    c =
      factories: factories
      values:
        xs: [1, 2, 3, 6]

    hinoki.get(c, 'meanOfSquares').then (meanOfSquares) ->
      test.equals meanOfSquares, 12.5
      test.deepEqual c.values,
        xs: [1, 2, 3, 6]
        count: 4
        meanOfSquares: 12.5
      test.done()

  'ask for variance': (test) ->
    c =
      factories: factories
      values:
        xs: [1, 2, 3, 6]

    hinoki.get(c, 'variance').then (variance) ->
      test.equals variance, 3.5
      test.deepEqual c.values,
        xs: [1, 2, 3, 6]
        count: 4
        mean: 3
        meanOfSquares: 12.5
        variance: 3.5
      test.done()
