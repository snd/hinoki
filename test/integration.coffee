Promise = require 'bluebird'
helfer = require 'helfer'

hinoki = require '../src/hinoki'

module.exports =

  'get value': (test) ->
    source = ->
      test.ok false
    lifetime =
      x: 1

    hinoki(source, lifetime, 'x').then (x) ->
      test.equal x, 1
      test.done()

  'get null value': (test) ->
    source = ->
      test.ok false
    lifetime =
      x: null

    hinoki(source, lifetime, 'x').then (x) ->
      test.ok helfer.isNull x
      test.done()

  'sync get from factory without dependencies': (test) ->
    source = hinoki.source
      x: -> 1
    lifetime = {}

    hinoki(source, lifetime, 'x').then (x) ->
      test.equal x, 1
      test.equal lifetime.x, 1
      test.done()

  'sync get null from factory without dependencies': (test) ->
    source = hinoki.source
      x: -> null
    lifetime = {}

    hinoki(source, lifetime, 'x').then (x) ->
      test.ok helfer.isNull x
      test.ok helfer.isNull lifetime.x
      test.done()

  'async get from factory without dependencies': (test) ->
    source = hinoki.source
      x: -> Promise.resolve 1
    lifetime = {}

    hinoki(source, lifetime, 'x').then (x) ->
      test.equal x, 1
      test.equal lifetime.x, 1
      test.done()

  'async get null from factory without dependencies': (test) ->
    source = hinoki.source
      x: -> Promise.resolve null
    lifetime = {}

    hinoki(source, lifetime, 'x').then (x) ->
      test.ok helfer.isNull x
      test.ok helfer.isNull lifetime.x
      test.done()

  'sync get with dependencies': (test) ->
    source = hinoki.source
      x: (y) -> 1 + y
      y: -> 1
    lifetime = {}

    hinoki(source, lifetime, 'x').then (x) ->
      test.equal x, 2
      test.deepEqual lifetime,
        x: 2
        y: 1
      test.done()

  'sync get null with dependencies': (test) ->
    source = hinoki.source
      x: (y) -> null
      y: -> 1
    lifetime = {}

    hinoki(source, lifetime, 'x').then (x) ->
      test.ok helfer.isNull x
      test.ok helfer.isNull lifetime.x
      test.done()

  'injectable is injected correctly': (test) ->
    source = hinoki.source
      a: -> 0
      b: -> 1
      c: (a, b) -> a + b
      d: (b, c) -> b + c
      e: (c, d) -> c + d
      f: (d, e) -> d + e
      g: (e, f) -> e + f
      h: (f, g) -> f + g
    lifetime = {}

    hinoki(source, lifetime, (a, b, c, d, e, f, g, h) ->
      [a, b, c, d, e, f, g, h]
    ).then (fibonacci) ->
      test.deepEqual fibonacci, [0, 1, 1, 2, 3, 5, 8, 13]
      test.done()

  'a value is cached in the last lifetime that contains values it directly or indirectly depends on': (test) ->
    req = {}
    res = {}
    params = {}
    next = ->
    currentUser = {}
    env = {}
    databaseConnection = {}
    isUserAllowedToAccessResource = ->
    selectUser = ->
    databaseUrl = 'kjsldkfjd'

    source = hinoki.source
      currentUser: (req, selectUser) -> currentUser
      isCurrentUserAllowedToAccessResource: (params, currentUser) -> true
      env: -> env
      databaseUrl: (env) -> databaseUrl
      databaseConnection: (databaseUrl) -> databaseConnection
      isUserAllowedToAccessResource: (databaseConnection) -> isUserAllowedToAccessResource
      selectUser: (databaseConnection) -> selectUser

    applicationLifetime = {}

    requestLifetime =
      req: req
      res: res

    middlewareLifetime =
      params: params
      next: next

    lifetimes = [
      applicationLifetime
      requestLifetime
      middlewareLifetime
    ]

    hinoki source, lifetimes, (isCurrentUserAllowedToAccessResource) ->
      test.deepEqual applicationLifetime,
        env: env
        databaseUrl: databaseUrl
        databaseConnection: databaseConnection
        selectUser: selectUser
      test.deepEqual requestLifetime,
        req: req
        res: res
        currentUser: currentUser
      test.deepEqual middlewareLifetime,
        params: params
        next: next
        isCurrentUserAllowedToAccessResource: true

      test.done()

  'a factory is called no more than once': (test) ->
    callsTo =
      a: 0
      b: 0
      c: 0
      d: 0

    source = hinoki.source
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
    lifetime = {}

    hinoki(source, lifetime, 'a').then (a) ->
      test.equal callsTo.a, 1
      test.equal callsTo.b, 1
      test.equal callsTo.c, 1
      test.equal callsTo.d, 1
      test.equal a, 23
      test.done()

  'promises awaiting resolution are cached and reused': (test) ->
    test.expect 8
    object = {}
    source = hinoki.source
      a: ->
        # here a new object is created
        Promise.delay object, 10
    lifetime = {}

    p1 = hinoki(source, lifetime, 'a')
    test.ok lifetime.a?
    # the first promise has one step more which handles caching
    # and cleanup of promise caching
    test.notEqual p1, lifetime.a
    # ask again
    p2 = hinoki(source, lifetime, 'a')
    test.equal p2, lifetime.a
    p3 = hinoki(source, lifetime, 'a')
    test.equal p3, lifetime.a

    Promise.all([p1, p2, p3]).then ([a1, a2, a3]) ->
      # three pointers to the same object!
      test.equal a1, object
      test.equal a1, a2
      test.equal a2, a3
      test.equal lifetime.a, object
      test.done()

  'all dependent promises are created without interleaving': (test) ->
    test.expect 20
    a = {}
    source = hinoki.source
      a: ->
        test.ok lifetime.a?
        test.ok lifetime.b?
        test.ok lifetime.c?
        Promise.delay a, 10
      b: (a) ->
        test.ok lifetime.b?
        test.ok lifetime.c?
        Promise.delay {a: a}, 10
      c: (b) ->
        test.ok lifetime.c?
        Promise.delay {b: b}, 10
    lifetime = {}

    promiseCWithCleanup = hinoki(source, lifetime, 'c')

    promiseA = lifetime.a
    promiseB = lifetime.b
    promiseC = lifetime.c

    test.ok promiseA?
    test.ok promiseB?
    test.ok promiseC?

    test.notEqual promiseCWithCleanup, hinoki(source, lifetime, 'c')

    # these are already awaiting resolution
    # getting them again returns the cached promises
    test.equal promiseA, hinoki(source, lifetime, 'a')
    test.equal promiseB, hinoki(source, lifetime, 'b')
    test.equal promiseC, hinoki(source, lifetime, 'c')

    Promise.all([promiseCWithCleanup, promiseA, promiseB, promiseC])
      .then ([valueCWithCleanup, valueA, valueB, valueC]) ->
        test.equal valueA, a
        test.equal valueB.a, valueA
        test.equal valueC.b, valueB
        # both promises resolve to the identical value
        test.equal valueCWithCleanup, valueC
        test.equal lifetime.a, valueA
        test.equal lifetime.b, valueB
        test.equal lifetime.c, valueC
        test.done()

  'promise in promise': (test) ->
    value = {}
    promise = Promise.resolve value
    promisePromise = Promise.resolve promise

    source = hinoki.source
      a: -> promisePromise
    lifetime = {}

    hinoki source, lifetime, (a) ->
      test.equal a, value
      test.done()

  'lifetime can be omitted': (test) ->
    source = hinoki.source
      a: -> 1
      b: (a) -> a + 1
      c: (b) -> b + 1
    hinoki source, (c) ->
      test.equal c, 3
      test.done()

  'flat factory objects': (test) ->
    source = hinoki.source
      alpha:
        bravo: (bravo) -> bravo
        charlie: (charlie) -> charlie
        delta: (delta) -> delta
      bravo: -> 'bravo'
      charlie: -> 'charlie'
      delta: -> 'delta'

    lifetime = {}

    hinoki source, lifetime, (alpha) ->
      test.deepEqual alpha,
        bravo: 'bravo'
        charlie: 'charlie'
        delta: 'delta'
      test.done()

  'flat factory arrays': (test) ->
    source = hinoki.source
      alpha: [
        (bravo) -> bravo
        (charlie) -> charlie
        (delta) -> delta
      ]
      bravo: -> 'bravo'
      charlie: -> 'charlie'
      delta: -> 'delta'

    lifetime = {}

    hinoki source, lifetime, (alpha) ->
      test.deepEqual alpha, [
        'bravo'
        'charlie'
        'delta'
      ]
      test.done()

  'nested': (test) ->
    source = hinoki.source
      alpha:
        bravo:
          charlie:
            delta: (delta) -> delta
            echo:
              foxtrot: (bravo) -> bravo
              golf: (charlie) -> charlie
      bravo: -> 'bravo'
      charlie: -> 'charlie'
      delta: -> 'delta'

    lifetime = {}

    hinoki source, lifetime, (alpha) ->
      test.deepEqual alpha,
        bravo:
          charlie:
            delta: 'delta'
            echo:
              foxtrot: 'bravo'
              golf: 'charlie'
      test.done()
