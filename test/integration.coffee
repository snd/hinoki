Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'get value': (test) ->
    c =
      values:
        x: 1

    hinoki.get(c, 'x').then (x) ->
      test.equals x, 1
      test.equals c.values.x, 1
      test.done()

  'get null value': (test) ->
    c =
      values:
        x: null

    hinoki.get(c, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.done()

  'sync get from factory': (test) ->
    c =
      factories:
        x: -> 1

    hinoki.get(c, 'x').then (x) ->
      test.equals x, 1
      test.equals c.values.x, 1
      test.done()

  'sync get null from factory': (test) ->
    c =
      factories:
        x: -> null

    hinoki.get(c, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.ok hinoki.isNull c.values.x
      test.done()

  'async get from factory': (test) ->
    c =
      factories:
        x: -> Promise.resolve 1

    hinoki.get(c, 'x').then (x) ->
      test.equals x, 1
      test.equals c.values.x, 1
      test.done()

  'async get null from factory': (test) ->
    c =
      factories:
        x: -> Promise.resolve null

    hinoki.get(c, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.ok hinoki.isNull c.values.x
      test.done()

  'sync get with dependencies': (test) ->
    c =
      factories:
        x: (y) -> 1 + y
        y: -> 1

    hinoki.get(c, 'x').then (x) ->
      test.equals x, 2
      test.done()

  'sync get null with dependencies': (test) ->
    c =
      factories:
        x: (y) -> null
        y: -> 1

    hinoki.get(c, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.ok hinoki.isNull c.values.x
      test.done()

  'containers are tried in order. values are created in container that resolved factory': (test) ->
    c1 =
      factories:
        a: (b) ->
          b + 1

    c2 =
      factories:
        b: (c) ->
          c + 1

    c3 =
      factories:
        c: (d) ->
          d + 1
        d: ->
          1

    hinoki.get([c1, c2, c3], ['a', 'd']).spread (a, d) ->
      test.equals a, 4
      test.equals d, 1

      test.equals c1.values.a, 4
      test.equals c2.values.b, 3
      test.equals c3.values.c, 2
      test.equals c3.values.d, 1

      test.done()

  'containers can not depend on previous containers': (test) ->
    c1 =
      factories:
        a: ->
          1

    c2 =
      factories:
        b: (a) ->
          a + 1

    hinoki.get([c1, c2], 'b').catch (error) ->
      test.equals error.type, 'UnresolvableFactoryError'
      test.deepEqual error.path, ['a', 'b']
      test.done()

  'resolvers wrap around default resolver': (test) ->
    a = {}
    b = {}

    c =
      factories:
        a: -> a

    c2 =
      factories:
        b: -> b

    c.resolvers = [
      (query, inner) ->
        test.equals query.container, c
        test.deepEqual query.path, ['a']
        inner
          container: c2
          path: ['b']
    ]

    hinoki.get(c, 'a').then (value) ->
      test.equals b, value
      test.equals c2.values.b, value
      test.done()

  'resolvers wrap around inner resolvers': (test) ->
    c = {}
    c2 = {}
    c3 = {}

    value = {}

    c.resolvers = [
      (query, inner) ->
        test.deepEqual query,
          container: c
          path: ['a']
        inner
          container: c2
          path: ['b']
      (query) ->
        test.deepEqual query,
          container: c2
          path: ['b']
        {
          factory: ->
            value
          container: c3
          path: ['c']
        }
    ]

    hinoki.get(c, 'a').then (a) ->
      test.equals a, value
      test.equals c3.values.c, value
      test.done()

  'a factory is called no more than once': (test) ->
    callsTo =
      a: 0
      b: 0
      c: 0
      d: 0

    c =
      factories:
        a: (b, c) ->
          test.ok callsTo.a < 2
          Promise.delay(b + c, 40)
        b: (d) ->
          test.ok callsTo.b < 2
          Promise.delay(d + 1, 20)
        c: (d) ->
          test.ok callsTo.c < 2
          Promise.delay(d + 2, 30)
        d: ->
          test.ok callsTo.d < 2
          Promise.delay(10, 10)

    hinoki.get(c, 'a').then (a) ->
      test.equals a, 23
      test.done()
