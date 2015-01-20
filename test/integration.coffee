Promise = require 'bluebird'

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

    hinoki.get([c1, c2], 'b').catch hinoki.UnresolvableError, (error) ->
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
          callsTo.a++
          Promise.delay(b + c, 40)
        b: (d) ->
          callsTo.b++
          Promise.delay(d + 1, 20)
        c: (d) ->
          callsTo.c++
          Promise.delay(d + 2, 30)
        d: ->
          callsTo.d++
          Promise.delay(10, 10)

    hinoki.get(c, 'a').then (a) ->
      test.equal callsTo.a, 1
      test.equal callsTo.b, 1
      test.equal callsTo.c, 1
      test.equal callsTo.d, 1
      test.equal a, 23
      test.done()

  'promises awaiting resolution are cached and reused': (test) ->
    test.expect 8
    c =
      factories:
        a: ->
          # here a new object is created
          Promise.delay {}, 10

    p1 = hinoki.get(c, 'a')
    test.ok c.promisesAwaitingResolution.a?
    # the first promise has one step more which handles caching
    # and cleanup of promise caching
    test.notEqual p1, c.promisesAwaitingResolution.a
    p2 = hinoki.get(c, 'a')
    test.equal p2, c.promisesAwaitingResolution.a
    p3 = hinoki.get(c, 'a')
    test.equal p3, c.promisesAwaitingResolution.a

    Promise.all([p1, p2, p3]).then ([a1, a2, a3]) ->
      # three pointers to the same object!
      test.equal 'object', typeof a1
      test.equal a1, a2
      test.equal a2, a3
      test.ok not c.promisesAwaitingResolution?.a?
      test.done()

  'all dependent promises are created without interleaving': (test) ->
    test.expect 18
    container =
      factories:
        a: ->
          test.ok container.promisesAwaitingResolution.a?
          test.ok container.promisesAwaitingResolution.b?
          test.ok container.promisesAwaitingResolution.c?
          Promise.delay {}, 10
        b: (a) ->
          test.ok container.promisesAwaitingResolution.b?
          test.ok container.promisesAwaitingResolution.c?
          Promise.delay {a: a}, 10
        c: (b) ->
          test.ok container.promisesAwaitingResolution.c?
          Promise.delay {b: b}, 10

    cWithCleanup = hinoki.get(container, 'c')

    a = container.promisesAwaitingResolution.a
    b = container.promisesAwaitingResolution.b
    c = container.promisesAwaitingResolution.c
    test.ok a?
    test.ok b?
    test.ok c?
    test.notEqual cWithCleanup, hinoki.get(container, 'c')
    test.equal a, hinoki.get(container, 'a')
    test.equal b, hinoki.get(container, 'b')
    test.equal c, hinoki.get(container, 'c')

    Promise.all([cWithCleanup, a, b, c]).then ([cWithCleanup, a, b, c]) ->
      test.equal c.b, b
      test.equal b.a, a
      test.equal 'object', typeof a
      test.equal c, cWithCleanup
      test.ok not container.promisesAwaitingResolution?
      test.done()

  'promises awaiting resolution are not cached and reused with nocache': (test) ->
    test.expect 7
    c =
      factories:
        a: ->
          # here a new object is created
          Promise.delay {}, 10

    c.factories.a.$nocache = true

    p1 = hinoki.get(c, 'a')
    test.ok not c.promisesAwaitingResolution?.a?
    # the first promise has one step more which handles caching
    # and cleanup of promise caching
    p2 = hinoki.get(c, 'a')
    test.ok not c.promisesAwaitingResolution?.a?
    p3 = hinoki.get(c, 'a')
    test.ok not c.promisesAwaitingResolution?.a?

    Promise.all([p1, p2, p3]).then ([a1, a2, a3]) ->
      # three different objects!
      test.equal 'object', typeof a1
      test.notEqual a1, a2
      test.notEqual a2, a3
      test.ok not c.promisesAwaitingResolution?.a?
      test.done()

  'resolvers wrap around default resolver': (test) ->
    a = {}
    b = {}

    c =
      factories:
        a: -> a
        b: -> b

    c.resolvers = [
      (name, container, inner) ->
        test.equal name, 'a'
        test.equal container, c
        inner 'b'
    ]

    hinoki.get(c, 'a').then (value) ->
      test.equal b, value
      test.equal c.values.b, value
      test.done()

  'resolvers wrap around inner resolvers': (test) ->
    c = {}

    value = {}

    c.resolvers = [
      (name, container, inner) ->
        test.equal name, 'a'
        test.equal container, c
        inner 'b'
      (name, container, inner) ->
        test.equal name, 'b'
        test.equal container, c
        {
          factory: -> value
          name: 'c'
        }
    ]

    hinoki.get(c, 'a').then (a) ->
      test.equal a, value
      test.equal c.values.c, value
      test.done()

  'a resolver can disable caching': (test) ->
    c = {}

    value = {}

    c.resolvers = [
      (name, container, inner) ->
        test.equal container, c
        test.equal name, 'a'
        {
          nocache: true
          name: name
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
    test.expect 5
    resolver = (name, container, inner) ->
      if name is 'bravo'
        {
          name: 'bravo'
          factory: (charlie) ->
            charlie.split('').reverse().join('')
          nocache: true
        }
      else
        inner name
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
          alpha: 'alpha'
          charlie: 'charlie'
          alpha_charlie: 'alpha_charlie'
          bravo_charlie: 'eilrahc_charlie'
          alpha_bravo: 'alpha_eilrahc'
        test.ok not container.promisesAwaitingResolution?
        test.done()
