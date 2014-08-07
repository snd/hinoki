Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'get value': (test) ->
    c = hinoki.newContainer {},
      x: 1

    hinoki.get(c, 'x').then (x) ->
      test.equals x, 1
      test.equals c.values.x, 1
      test.done()

  'get null value': (test) ->
    c = hinoki.newContainer {},
      x: null

    hinoki.get(c, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.done()

  'sync get from factory': (test) ->
    c = hinoki.newContainer
      x: -> 1

    hinoki.get(c, 'x').then (x) ->
      test.equals x, 1
      test.equals c.values.x, 1
      test.done()

  'sync get null from factory': (test) ->
    c = hinoki.newContainer
      x: -> null

    hinoki.get(c, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.ok hinoki.isNull c.values.x
      test.done()

  'async get from factory': (test) ->
    c = hinoki.newContainer
      x: -> Promise.resolve 1

    hinoki.get(c, 'x').then (x) ->
      test.equals x, 1
      test.equals c.values.x, 1
      test.done()

  'async get null from factory': (test) ->
    c = hinoki.newContainer
      x: -> Promise.resolve null

    hinoki.get(c, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.ok hinoki.isNull c.values.x
      test.done()

  'sync get with dependencies': (test) ->
    c = hinoki.newContainer
      x: (y) -> 1 + y
      y: -> 1

    hinoki.get(c, 'x').then (x) ->
      test.equals x, 2
      test.done()

  'sync get null with dependencies': (test) ->
    c = hinoki.newContainer
      x: (y) -> null
      y: -> 1

    hinoki.get(c, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.ok hinoki.isNull c.values.x
      test.done()

  'containers are tried in order. values are created in container that resolved factory': (test) ->
    c1 = hinoki.newContainer
      a: (b) ->
        b + 1

    c2 = hinoki.newContainer
      b: (c) ->
        c + 1

    c3 = hinoki.newContainer
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
    c1 = hinoki.newContainer
      a: ->
        1

    c2 = hinoki.newContainer
      b: (a) ->
        a + 1

    hinoki.get([c1, c2], 'b').catch (error) ->
      test.equals error.type, 'UnresolvableFactoryError'
      test.deepEqual error.path, ['a', 'b']
      test.done()

  'factory resolvers wrap around default resolver': (test) ->
    test.expect 3

    a = {}
    b = {}

    c = hinoki.newContainer
      a: -> a

    c2 = hinoki.newContainer
      b: -> b

    c.factoryResolvers = [
      (container, name, inner) ->
        test.equals container, c
        test.equals name, 'a'
        inner c2, 'b'
    ]

    hinoki.get(c, 'a').then (value) ->
      test.equals b, value
      test.done()

  'factory resolvers wrap around inner resolvers': (test) ->
    test.expect 3
    c = hinoki.newContainer()

    c2 = {}

    value = {}

    c.factoryResolvers = [
      (container, name, inner) ->
        inner c2, 'b'
      (container, name) ->
        test.equals container, c2
        test.equals name, 'b'
        ->
          value
    ]

    hinoki.get(c, 'a').then (a) ->
      test.equals a, value
      test.done()

  'value resolvers wrap around default resolver': (test) ->
    test.expect 3

    a = {}
    b = {}

    c =
      values:
        a: a

    c2 =
      values:
        b: b

    c.valueResolvers = [
      (container, name, inner) ->
        test.equals container, c
        test.equals name, 'a'
        inner c2, 'b'
    ]

    hinoki.get(c, 'a').then (value) ->
      test.equals b, value
      test.done()

  'value resolvers wrap around inner resolvers': (test) ->
    test.expect 3
    c = hinoki.newContainer()

    c2 = {}

    value = {}

    c.valueResolvers = [
      (container, name, inner) ->
        inner c2, 'b'
      (container, name) ->
        test.equals container, c2
        test.equals name, 'b'
        value
    ]

    hinoki.get(c, 'a').then (a) ->
      test.equals a, value
      test.done()

  'value resolvers pass on null values': (test) ->
    test.expect 1
    c = hinoki.newContainer()

    c2 = {}

    c.valueResolvers = [
      (container, name, inner) ->
        null
    ]

    hinoki.get(c, 'a').then (a) ->
      test.ok null is a
      test.done()

  'a factory is called no more than once': (test) ->
    test.expect 5

    callsTo =
      a: 0
      b: 0
      c: 0
      d: 0

    c = hinoki.newContainer
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
