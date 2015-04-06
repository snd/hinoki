Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'get value': (test) ->
    lifetime =
      values:
        x: 1

    hinoki(lifetime, 'x').then (x) ->
      test.equal x, 1
      test.equal lifetime.values.x, 1
      test.done()

  'get null value': (test) ->
    lifetime =
      values:
        x: null

    hinoki(lifetime, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.done()

  'sync get from factory': (test) ->
    lifetime =
      factories:
        x: -> 1

    hinoki(lifetime, 'x').then (x) ->
      test.equal x, 1
      test.equal lifetime.values.x, 1
      test.done()

  'sync get null from factory': (test) ->
    lifetime =
      factories:
        x: -> null

    hinoki(lifetime, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.ok hinoki.isNull lifetime.values.x
      test.done()

  'async get from factory': (test) ->
    lifetime =
      factories:
        x: -> Promise.resolve 1

    hinoki(lifetime, 'x').then (x) ->
      test.equal x, 1
      test.equal lifetime.values.x, 1
      test.done()

  'async get null from factory': (test) ->
    lifetime =
      factories:
        x: -> Promise.resolve null

    hinoki(lifetime, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.ok hinoki.isNull lifetime.values.x
      test.done()

  'sync get with dependencies': (test) ->
    lifetime =
      factories:
        x: (y) -> 1 + y
        y: -> 1

    hinoki(lifetime, 'x').then (x) ->
      test.equal x, 2
      test.done()

  'sync get null with dependencies': (test) ->
    lifetime =
      factories:
        x: (y) -> null
        y: -> 1

    hinoki(lifetime, 'x').then (x) ->
      test.ok hinoki.isNull x
      test.ok hinoki.isNull lifetime.values.x
      test.done()

  'injectable is injected correctly': (test) ->
    lifetime =
      factories:
        a: -> 0
        b: -> 1
        c: (a, b) -> a + b
        d: (b, c) -> b + c
        e: (c, d) -> c + d
        f: (d, e) -> d + e
        g: (e, f) -> e + f
        h: (f, g) -> f + g

    hinoki(lifetime, (a, b, c, d, e, f, g, h) ->
      [a, b, c, d, e, f, g, h]
    ).then (fibonacci) ->
      test.deepEqual fibonacci, [0, 1, 1, 2, 3, 5, 8, 13]
      test.done()

  'lifetimes are tried in order. values are created in lifetime that resolved factory': (test) ->
    l1 =
      factories:
        a: (b) ->
          b + 1

    l2 =
      factories:
        b: (c) ->
          c + 1

    l3 =
      factories:
        c: (d) ->
          d + 1
        d: ->
          1

    hinoki([l1, l2, l3], ['a', 'd']).spread (a, d) ->
      test.equal a, 4
      test.equal d, 1

      test.equal l1.values.a, 4
      test.equal l2.values.b, 3
      test.equal l3.values.c, 2
      test.equal l3.values.d, 1

      test.done()

  'lifetimes can not depend on previous lifetimes': (test) ->
    l1 =
      factories:
        a: ->
          1

    l2 =
      factories:
        b: (a) ->
          a + 1

    hinoki([l1, l2], 'b').catch hinoki.UnresolvableError, (error) ->
      test.deepEqual error.path, ['a', 'b']
      test.done()

  'a factory is called no more than once': (test) ->
    callsTo =
      a: 0
      b: 0
      c: 0
      d: 0

    lifetime =
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

    hinoki(lifetime, 'a').then (a) ->
      test.equal callsTo.a, 1
      test.equal callsTo.b, 1
      test.equal callsTo.c, 1
      test.equal callsTo.d, 1
      test.equal a, 23
      test.done()

  'promises awaiting resolution are cached and reused': (test) ->
    test.expect 8
    lifetime =
      factories:
        a: ->
          # here a new object is created
          Promise.delay {}, 10

    p1 = hinoki(lifetime, 'a')
    test.ok lifetime.promisesAwaitingResolution.a?
    # the first promise has one step more which handles caching
    # and cleanup of promise caching
    test.notEqual p1, lifetime.promisesAwaitingResolution.a
    p2 = hinoki(lifetime, 'a')
    test.equal p2, lifetime.promisesAwaitingResolution.a
    p3 = hinoki(lifetime, 'a')
    test.equal p3, lifetime.promisesAwaitingResolution.a

    Promise.all([p1, p2, p3]).then ([a1, a2, a3]) ->
      # three pointers to the same object!
      test.equal 'object', typeof a1
      test.equal a1, a2
      test.equal a2, a3
      test.ok not lifetime.promisesAwaitingResolution?.a?
      test.done()

  'all dependent promises are created without interleaving': (test) ->
    test.expect 18
    lifetime =
      factories:
        a: ->
          test.ok lifetime.promisesAwaitingResolution.a?
          test.ok lifetime.promisesAwaitingResolution.b?
          test.ok lifetime.promisesAwaitingResolution.c?
          Promise.delay {}, 10
        b: (a) ->
          test.ok lifetime.promisesAwaitingResolution.b?
          test.ok lifetime.promisesAwaitingResolution.c?
          Promise.delay {a: a}, 10
        c: (b) ->
          test.ok lifetime.promisesAwaitingResolution.c?
          Promise.delay {b: b}, 10

    promiseCWithCleanup = hinoki(lifetime, 'c')

    promiseA = lifetime.promisesAwaitingResolution.a
    promiseB = lifetime.promisesAwaitingResolution.b
    promiseC = lifetime.promisesAwaitingResolution.c

    test.ok promiseA?
    test.ok promiseB?
    test.ok promiseC?

    test.notEqual promiseCWithCleanup, hinoki(lifetime, 'c')

    # these are already awaiting resolution
    # getting them again returns the cached promises
    test.equal promiseA, hinoki(lifetime, 'a')
    test.equal promiseB, hinoki(lifetime, 'b')
    test.equal promiseC, hinoki(lifetime, 'c')

    Promise.all([promiseCWithCleanup, promiseA, promiseB, promiseC])
      .then ([valueCWithCleanup, valueA, valueB, valueC]) ->
        test.equal 'object', typeof valueA
        test.equal valueB.a, valueA
        test.equal valueC.b, valueB
        # both promises resolve to the identical value
        test.equal valueCWithCleanup, valueC
        test.ok not lifetime.promisesAwaitingResolution?
        test.done()

  'promises awaiting resolution are not cached and reused with nocache': (test) ->
    test.expect 7
    lifetime =
      factories:
        a: ->
          # here a new object is created
          Promise.delay {}, 10

    lifetime.factories.a.$nocache = true

    p1 = hinoki(lifetime, 'a')
    test.ok not lifetime.promisesAwaitingResolution?.a?
    # the first promise has one step more which handles caching
    # and cleanup of promise caching
    p2 = hinoki(lifetime, 'a')
    test.ok not lifetime.promisesAwaitingResolution?.a?
    p3 = hinoki(lifetime, 'a')
    test.ok not lifetime.promisesAwaitingResolution?.a?

    Promise.all([p1, p2, p3]).then ([a1, a2, a3]) ->
      # three different objects!
      test.equal 'object', typeof a1
      test.notEqual a1, a2
      test.notEqual a2, a3
      test.ok not lifetime.promisesAwaitingResolution?.a?
      test.done()

  'a factory with $nocache property is not cached': (test) ->
    lifetime =
      factories:
        x: -> 1

    lifetime.factories.x.$nocache = true

    hinoki(lifetime, 'x').then (x) ->
      test.equal x, 1
      test.ok not lifetime.values?
      test.done()

  'single factory source function': (test) ->
    lifetime =
      factories: (name) ->
        switch name
          when 'a' then -> 0
          when 'b' then -> 1
          when 'c' then (a, b) -> a + b
          when 'd' then (b, c) -> b + c

    hinoki(lifetime, 'd')
      .then (d) ->
        test.equal d, 2
        hinoki(lifetime, 'e')
      .catch hinoki.UnresolvableError, (error) ->
        test.equal error.message, "unresolvable name 'e' (e)"
        test.done()

  'multiple factory sources': (test) ->
    lifetime =
      factories: [
        (name) ->
          if name is 'd'
            (b, c) -> b + c
        {
          a: -> 0
        }
        (name) ->
          if name is 'b'
            -> 1
        {
          c: (a, b) -> a + b
        }
      ]

    hinoki(lifetime, 'd')
      .then (d) ->
        test.equal d, 2
        hinoki(lifetime, 'e')
      .catch hinoki.UnresolvableError, (error) ->
        test.equal error.message, "unresolvable name 'e' (e)"
        test.done()
