test = require 'tape'
hinoki = require '../lib/hinoki'

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

test 'ask for count', (t) ->
  source = hinoki.source factories
  lifetime =
    xs: [1, 2, 3, 6]

  hinoki(source, lifetime, 'count')
    .then (count) ->
      t.equal count, 4
      t.deepEqual lifetime,
        xs: [1, 2, 3, 6]
        count: 4
      t.end()

test 'ask for mean', (t) ->
  source = hinoki.source factories
  lifetime =
    xs: [1, 2, 3, 6]

  hinoki(source, lifetime, 'mean').then (mean) ->
    t.equal mean, 3
    t.deepEqual lifetime,
      xs: [1, 2, 3, 6]
      count: 4
      mean: 3
    t.end()

test 'ask for meanOfSquares', (t) ->
  source = hinoki.source factories
  lifetime =
    xs: [1, 2, 3, 6]

  hinoki(source, lifetime, 'meanOfSquares').then (meanOfSquares) ->
    t.equal meanOfSquares, 12.5
    t.deepEqual lifetime,
      xs: [1, 2, 3, 6]
      count: 4
      meanOfSquares: 12.5
    t.end()

test 'ask for variance', (t) ->
  source = hinoki.source factories
  lifetime =
    xs: [1, 2, 3, 6]

  hinoki(source, lifetime, 'variance').then (variance) ->
    t.equal variance, 3.5
    t.deepEqual lifetime,
      xs: [1, 2, 3, 6]
      count: 4
      mean: 3
      meanOfSquares: 12.5
      variance: 3.5
    t.end()
