test = require 'tape'
Promise = require 'bluebird'
helfer = require 'helfer'

hinoki = require '../lib/hinoki'

test 'get value', (t) ->
  source = ->
    t.ok false
  lifetime =
    x: 1

  hinoki(source, lifetime, 'x').then (x) ->
    t.equal x, 1
    t.end()

test 'get null value', (t) ->
  source = ->
    t.ok false
  lifetime =
    x: null

  hinoki(source, lifetime, 'x').then (x) ->
    t.ok helfer.isNull x
    t.end()

test 'sync get from factory without dependencies', (t) ->
  source = hinoki.source
    x: -> 1
  lifetime = {}

  hinoki(source, lifetime, 'x').then (x) ->
    t.equal x, 1
    t.equal lifetime.x, 1
    t.end()

test 'sync get null from factory without dependencies', (t) ->
  source = hinoki.source
    x: -> null
  lifetime = {}

  hinoki(source, lifetime, 'x').then (x) ->
    t.ok helfer.isNull x
    t.ok helfer.isNull lifetime.x
    t.end()

test 'async get from factory without dependencies', (t) ->
  source = hinoki.source
    x: -> Promise.resolve 1
  lifetime = {}

  hinoki(source, lifetime, 'x').then (x) ->
    t.equal x, 1
    t.equal lifetime.x, 1
    t.end()

test 'async get null from factory without dependencies', (t) ->
  source = hinoki.source
    x: -> Promise.resolve null
  lifetime = {}

  hinoki(source, lifetime, 'x').then (x) ->
    t.ok helfer.isNull x
    t.ok helfer.isNull lifetime.x
    t.end()

test 'sync get with dependencies', (t) ->
  source = hinoki.source
    x: (y) -> 1 + y
    y: -> 1
  lifetime = {}

  hinoki(source, lifetime, 'x').then (x) ->
    t.equal x, 2
    t.deepEqual lifetime,
      x: 2
      y: 1
    t.end()

test 'sync get null with dependencies', (t) ->
  source = hinoki.source
    x: (y) -> null
    y: -> 1
  lifetime = {}

  hinoki(source, lifetime, 'x').then (x) ->
    t.ok helfer.isNull x
    t.ok helfer.isNull lifetime.x
    t.end()

test 'injectable is injected correctly', (t) ->
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
    t.deepEqual fibonacci, [0, 1, 1, 2, 3, 5, 8, 13]
    t.end()

test 'a value is cached in the last lifetime that contains values it directly or indirectly depends on', (t) ->
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
    t.deepEqual applicationLifetime,
      env: env
      databaseUrl: databaseUrl
      databaseConnection: databaseConnection
      selectUser: selectUser
    t.deepEqual requestLifetime,
      req: req
      res: res
      currentUser: currentUser
    t.deepEqual middlewareLifetime,
      params: params
      next: next
      isCurrentUserAllowedToAccessResource: true

    t.end()

test 'a factory is called no more than once', (t) ->
  callsTo =
    a: 0
    b: 0
    c: 0
    d: 0

  source = hinoki.source
    a: (b, c) ->
      callsTo.a++
      Promise.delay(40, b + c)
    b: (d) ->
      callsTo.b++
      Promise.delay(20, d + 1)
    c: (d) ->
      callsTo.c++
      Promise.delay(30, d + 2)
    d: ->
      callsTo.d++
      Promise.delay(10, 10)
  lifetime = {}

  hinoki(source, lifetime, 'a').then (a) ->
    t.equal callsTo.a, 1
    t.equal callsTo.b, 1
    t.equal callsTo.c, 1
    t.equal callsTo.d, 1
    t.equal a, 23
    t.end()

test 'promises awaiting resolution are cached and reused', (t) ->
  t.plan 8
  object = {}
  source = hinoki.source
    a: ->
      # here a new object is created
      Promise.delay 10, object
  lifetime = {}

  p1 = hinoki(source, lifetime, 'a')
  t.ok lifetime.a?
  # the first promise has one step more which handles caching
  # and cleanup of promise caching
  t.notEqual p1, lifetime.a
  # ask again
  p2 = hinoki(source, lifetime, 'a')
  t.equal p2, lifetime.a
  p3 = hinoki(source, lifetime, 'a')
  t.equal p3, lifetime.a

  Promise.all([p1, p2, p3]).then ([a1, a2, a3]) ->
    # three pointers to the same object!
    t.equal a1, object
    t.equal a1, a2
    t.equal a2, a3
    t.equal lifetime.a, object
    t.end()

test 'all dependent promises are created without interleaving', (t) ->
  t.plan 20
  a = {}
  source = hinoki.source
    a: ->
      t.ok lifetime.a?
      t.ok lifetime.b?
      t.ok lifetime.c?
      Promise.delay 10, a
    b: (a) ->
      t.ok lifetime.b?
      t.ok lifetime.c?
      Promise.delay 10, {a: a}
    c: (b) ->
      t.ok lifetime.c?
      Promise.delay 10, {b: b}
  lifetime = {}

  promiseCWithCleanup = hinoki(source, lifetime, 'c')

  promiseA = lifetime.a
  promiseB = lifetime.b
  promiseC = lifetime.c

  t.ok promiseA?
  t.ok promiseB?
  t.ok promiseC?

  t.notEqual promiseCWithCleanup, hinoki(source, lifetime, 'c')

  # these are already awaiting resolution
  # getting them again returns the cached promises
  t.equal promiseA, hinoki(source, lifetime, 'a')
  t.equal promiseB, hinoki(source, lifetime, 'b')
  t.equal promiseC, hinoki(source, lifetime, 'c')

  Promise.all([promiseCWithCleanup, promiseA, promiseB, promiseC])
    .then ([valueCWithCleanup, valueA, valueB, valueC]) ->
      t.equal valueA, a
      t.equal valueB.a, valueA
      t.equal valueC.b, valueB
      # both promises resolve to the identical value
      t.equal valueCWithCleanup, valueC
      t.equal lifetime.a, valueA
      t.equal lifetime.b, valueB
      t.equal lifetime.c, valueC
      t.end()

test 'promise in promise', (t) ->
  value = {}
  promise = Promise.resolve value
  promisePromise = Promise.resolve promise

  source = hinoki.source
    a: -> promisePromise
  lifetime = {}

  hinoki source, lifetime, (a) ->
    t.equal a, value
    t.end()

test 'lifetime can be omitted', (t) ->
  source = hinoki.source
    a: -> 1
    b: (a) -> a + 1
    c: (b) -> b + 1
  hinoki source, (c) ->
    t.equal c, 3
    t.end()

test 'flat factory objects', (t) ->
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
    t.deepEqual alpha,
      bravo: 'bravo'
      charlie: 'charlie'
      delta: 'delta'
    t.end()

test 'flat factory arrays', (t) ->
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
    t.deepEqual alpha, [
      'bravo'
      'charlie'
      'delta'
    ]
    t.end()

test 'nested factory objects and factory arrays', (t) ->
  source = hinoki.source
    alpha:
      bravo:
        charlie:
          delta: (delta) -> delta
          echo:
            foxtrot: (bravo) -> bravo
            golf: [
              (delta, bravo) -> delta + '_' + bravo
              [
                (charlie) -> charlie
                -> 'foxtrot'
              ]
            ]
    bravo: -> 'bravo'
    charlie: -> 'charlie'
    delta: -> 'delta'

  lifetime = {}

  hinoki source, lifetime, (alpha) ->
    t.deepEqual alpha,
      bravo:
        charlie:
          delta: 'delta'
          echo:
            foxtrot: 'bravo'
            golf: [
              'delta_bravo'
              [
                'charlie'
                'foxtrot'
              ]
            ]
    t.end()

test 'decorateSourceToAlsoLookupWithPrefix', (t) ->

  t.test 'original found', (t) ->
    value = {}
    source = hinoki.source
      a: -> value

    source = hinoki.decorateSourceToAlsoLookupWithPrefix source, 'my_'
    lifetime = {}

    hinoki source, lifetime, (a) ->
      t.equal a, value
      t.equal lifetime.a, value
      t.ok not lifetime.my_a?
      t.end()

  t.test 'already prefixed', (t) ->
    value = {}
    source = hinoki.source
      my_a: -> value

    source = hinoki.decorateSourceToAlsoLookupWithPrefix source, 'my_'
    lifetime = {}

    hinoki source, lifetime, (my_a) ->
      t.equal my_a, value
      t.equal lifetime.my_a, value
      t.ok not lifetime.a?
      t.end()

  t.test 'prefixed found', (t) ->
    value = {}
    source = hinoki.source
      my_a: -> value

    source = hinoki.decorateSourceToAlsoLookupWithPrefix source, 'my_'
    lifetime = {}

    hinoki source, lifetime, (a) ->
      t.equal a, value
      t.equal lifetime.my_a, value
      t.equal lifetime.a, value
      t.end()

  t.test 'not found', (t) ->
    source = hinoki.source {}

    source = hinoki.decorateSourceToAlsoLookupWithPrefix source, 'my_'
    lifetime = {}

    hinoki(source, lifetime, 'a').catch hinoki.NotFoundError, (error) ->
      t.equal error.message, "neither value nor factory found for `my_a` in path `my_a <- a`"
      t.deepEqual error.path, ['my_a', 'a']
      t.deepEqual lifetime, {}
      t.end()
