Promise = require 'bluebird'
util = require 'util'

hinoki = require '../src/hinoki'

module.exports =

  'get value': (test) ->
    c =
      values:
        x: 1

    hinoki.get(c, 'x').then (x) ->
      test.equal x, 1
      test.equal c.values.x, 1
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
      test.equal x, 1
      test.equal c.values.x, 1
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
      test.equal x, 1
      test.equal c.values.x, 1
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
      test.equal x, 2
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
      test.equal a, 4
      test.equal d, 1

      test.equal c1.values.a, 4
      test.equal c2.values.b, 3
      test.equal c3.values.c, 2
      test.equal c3.values.d, 1

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
      test.equal error.type, 'UnresolvableFactoryError'
      test.deepEqual error.path, ['a', 'b']
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
      test.equal a, 23
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
        test.equal query.container, c
        test.deepEqual query.path, ['a']
        inner
          container: c2
          path: ['b']
    ]

    hinoki.get(c, 'a').then (value) ->
      test.equal b, value
      test.equal c2.values.b, value
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
      test.equal a, value
      test.equal c3.values.c, value
      test.done()

  'a resolver can disable caching': (test) ->
    c = {}

    value = {}

    c.resolvers = [
      (query, inner) ->
        test.deepEqual query,
          container: c
          path: ['a']
        return {
          nocache: true
          container: c
          factory: ->
            value
        }
    ]

    hinoki.get(c, 'a').then (a) ->
      test.equal a, value
      test.ok not c.values?
      test.done()

  'a factory with $nocache property is not cached': (test) ->
    c =
      factories:
        x: -> 1

    c.factories.x.$nocache = true

    hinoki.get(c, 'x').then (x) ->
      test.equal x, 1
      test.ok not c.values?
      test.done()

  'mocking a factory for any require': (test) ->
    test.expect 4
    resolver = (query, inner) ->
      if query.path[0] is 'bravo'
        {
          container: query.container
          path: query.path
          factory: (charlie) ->
            charlie.split('').reverse().join('')
          nocache: true
        }
      else
        inner query
    container =
      factories:
        alpha: -> 'alpha'
        bravo: -> 'bravo'
        charlie: -> 'charlie'
        alpha_bravo: (alpha, bravo) ->
          alpha + '_' + bravo
        bravo_charlie: (bravo, charlie) ->
          bravo + '_' + charlie
        alpha_charlie: (alpha, charlie) ->
          alpha + '_' + charlie
      resolvers: [resolver]

    hinoki.get(container, ['alpha_bravo', 'bravo_charlie', 'alpha_charlie'])
      .spread (alpha_bravo, bravo_charlie, alpha_charlie) ->
        test.equal alpha_bravo, 'alpha_eilrahc'
        test.equal bravo_charlie, 'eilrahc_charlie'
        test.equal alpha_charlie, 'alpha_charlie'
        # note that bravo is not cached
        test.deepEqual container.values,
          alpha: 'alpha',
          charlie: 'charlie',
          alpha_charlie: 'alpha_charlie',
          bravo_charlie: 'eilrahc_charlie',
          alpha_bravo: 'alpha_eilrahc'
        test.done()

  'mocking a factory for requires from a specific other factory': (test) ->
    # test.expect 4
    resolver = (query, inner) ->
      if query.path[0] is 'bravo'
        # only mock out when required by bravo_charlie
        if query.path[1] is 'bravo_charlie'
          {
            container: query.container
            path: query.path
            factory: (charlie) ->
              charlie.split('').reverse().join('')
            nocache: true
          }
        else
          # use the normal bravo factory when required from other factories
          result = inner query

          # by default this will return a factory and then
          # the cached value on subsequent resolutions.
          # requires originating from bravo_charlie are not cached (nocache above).
          # requires from other factories are cached by default.

          # the under construction is a problem !!!
          # if bravo is already under construction by alpha_bravo
          # for example which reaches this code branch
          # then bravo_charlies special factory returned from this resolver
          # is ignored and bravo_charlie resolves to the same value as
          # alpha_charlie.
          # we can prevent this by disabling caching for all requires of bravo
          # use under construction only if the factory
          # and path used for construction are the same one
          #
          # output varies based on path and factory

          # under construction should key both based on the path and the factory!!!

          # result.nocache = true
          result
      else
        inner query
    container =
      factories:
        alpha: -> 'alpha'
        bravo: -> 'bravo'
        charlie: -> 'charlie'
        alpha_bravo: (alpha, bravo) ->
          alpha + '_' + bravo
        bravo_charlie: (bravo, charlie) ->
          bravo + '_' + charlie
        alpha_charlie: (alpha, charlie) ->
          alpha + '_' + charlie
      resolvers: [resolver]

    hinoki.get(
      container
      ['alpha_bravo', 'bravo_charlie', 'alpha_charlie']
    )
      .spread (alpha_bravo, bravo_charlie, alpha_charlie) ->
        test.equal alpha_bravo, 'alpha_bravo'
        test.equal bravo_charlie, 'eilrahc_charlie'
        test.equal alpha_charlie, 'alpha_charlie'
        # bravo is cached for all cases but the ones where
        # bravo_charlie requires it
        test.deepEqual container.values,
          alpha: 'alpha',
          charlie: 'charlie',
          bravo: 'bravo'
          alpha_charlie: 'alpha_charlie',
          bravo_charlie: 'eilrahc_charlie',
          alpha_bravo: 'alpha_bravo'
        test.done()

  'mocking a factory for all requires (and their requires...) from a specific factory': (test) ->
    test.done()
