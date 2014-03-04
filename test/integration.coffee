hinoki = require '../src/hinoki'

module.exports =

  'containers are tried in order. instances are created in container that resolved factory': (test) ->
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

    hinoki.inject [c1, c2, c3], (a, d) ->
      test.equals a, 4
      test.equals d, 1

      test.equals c1.instances.a, 4
      test.equals c2.instances.b, 3
      test.equals c3.instances.c, 2
      test.equals c3.instances.d, 1

      test.done()

  'containers can not depend on previous containers': (test) ->
    c1 = hinoki.newContainer
      a: ->
        1

    c2 = hinoki.newContainer
      b: (a) ->
        a + 1

    c2.emitter.on 'error', (error) ->
      test.equals error.type, 'unresolvableFactory'
      test.deepEqual error.id, ['a', 'b']
      test.done()

    hinoki.inject [c1, c2], (b) ->
      test.fail()

  'factory resolvers are tried in order until one returns a factory': (test) ->
    test.expect 5
    c = hinoki.newContainer()

    instance = {}

    c.factoryResolvers = [
      (container, id) ->
        test.equals container, c
        test.equals id, 'a'
        null
      (container, id) ->
        test.equals container, c
        test.equals id, 'a'
        ->
          instance
      (container, id) ->
        test.fail()
    ]

    hinoki.inject c, (a) ->
      test.equals a, instance
      test.done()
