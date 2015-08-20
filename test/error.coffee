test = require 'tape'
Promise = require 'bluebird'

hinoki = require '../lib/hinoki'

test 'errors can be catched as BaseError', (t) ->
  source = hinoki.source
    a: ->
  lifetime = {}

  hinoki(source, lifetime, 'a').catch hinoki.BaseError, (error) ->
    t.equal error.name, 'FactoryReturnedUndefinedError'
    t.end()

test 'NotFoundError', (t) ->
  source = ->
  lifetime = {}

  hinoki(source, lifetime, 'a').catch hinoki.NotFoundError, (error) ->
    t.equal error.message, "neither value nor factory found for `a` in path `a`"
    t.deepEqual error.path, ['a']
    t.deepEqual lifetime, {}
    t.end()

test 'CircularDependencyError', (t) ->
  t.test '2', (t) ->
    source = hinoki.source
      a: (a) ->
    lifetime = {}

    hinoki(source, lifetime, 'a').catch hinoki.CircularDependencyError, (error) ->
      t.equal error.name, 'CircularDependencyError'
      t.equal error.message, "circular dependency `a <- a`"
      if Error.captureStackTrace?
        t.equal 'string', typeof error.stack
        t.ok error.stack.split('\n').length > 8

      t.deepEqual error.path, ['a', 'a']
      t.deepEqual lifetime, {}

      t.end()

  t.test '3', (t) ->
    source = hinoki.source
      a: (b) ->
      b: (a) ->
    lifetime = {}

    hinoki(source, lifetime, 'a').catch hinoki.CircularDependencyError, (error) ->
      t.equal error.name, 'CircularDependencyError'
      t.equal error.message, "circular dependency `a <- b <- a`"
      if Error.captureStackTrace?
        t.equal 'string', typeof error.stack
        t.ok error.stack.split('\n').length > 8

      t.deepEqual error.path, ['a', 'b', 'a']
      t.deepEqual lifetime, {}

      t.end()

test 'ErrorInFactory', (t) ->
  exception = new Error 'fail'
  a = -> throw exception

  source = hinoki.source
    a: a
  lifetime = {}

  hinoki(source, lifetime, 'a').catch hinoki.ErrorInFactory, (error) ->
    t.equal error.name, 'ErrorInFactory'
    t.equal error.message, "error in factory for `a`. original error `Error: fail`"
    if Error.captureStackTrace?
      t.equal 'string', typeof error.stack
      t.ok error.stack.split('\n').length > 8

    t.deepEqual error.path, ['a']
    t.equal error.factory, a
    t.equal error.error, exception
    t.deepEqual lifetime, {}

    t.end()

test 'FactoryReturnedUndefinedError', (t) ->
  a = ->
  source = hinoki.source
    a: a
  lifetime = {}

  hinoki(source, lifetime, 'a').catch hinoki.FactoryReturnedUndefinedError, (error) ->
    t.equal error.name, 'FactoryReturnedUndefinedError'
    t.equal error.message, "factory for `a` returned undefined"
    if Error.captureStackTrace?
      t.equal 'string', typeof error.stack
      t.ok error.stack.split('\n').length > 8

    t.deepEqual error.path, ['a']
    t.equal error.factory, a
    t.deepEqual lifetime, {}

    t.end()

test 'PromiseRejectedError and that errored promises are removed', (t) ->
  rejection = new Error 'fail'
  a = -> Promise.reject rejection

  source = hinoki.source
    a: a
  lifetime = {}

  hinoki(source, lifetime, 'a').catch hinoki.PromiseRejectedError, (error) ->
    t.equal error.name, 'PromiseRejectedError'
    t.equal error.message, "promise returned from factory for `a` was rejected. original error `Error: fail`"
    if Error.captureStackTrace?
      t.equal 'string', typeof error.stack
      t.ok error.stack.split('\n').length > 8

    t.deepEqual error.path, ['a']
    t.equal error.error, rejection
    t.equal error.factory, a
    t.deepEqual lifetime, {}

    t.end()

test 'BadFactoryError', (t) ->

  t.test 'flat', (t) ->
    source = hinoki.source
      a: 1
    lifetime = {}

    hinoki(source, lifetime, 'a').catch hinoki.BadFactoryError, (error) ->
      t.equal error.name, 'BadFactoryError'
      t.equal error.message, "factory for `a` has to be a function, object of factories or array of factories but is `number`"
      if Error.captureStackTrace?
        t.equal 'string', typeof error.stack
        t.ok error.stack.split('\n').length > 8

      t.deepEqual error.path, ['a']
      t.equal error.factory, 1
      t.deepEqual lifetime, {}

      t.end()

  t.test 'array', (t) ->
    source = hinoki.source
      a:
        b:
          c: [
            -> 'a'
            -> 'b'
            'fail'
          ]
      b: (a) -> a
    lifetime = {}

    hinoki(source, lifetime, 'b').catch hinoki.BadFactoryError, (error) ->
      t.equal error.name, 'BadFactoryError'
      t.equal error.message, "factory for `a[b][c][2]` has to be a function, object of factories or array of factories but is `string`"
      if Error.captureStackTrace?
        t.equal 'string', typeof error.stack
        t.ok error.stack.split('\n').length > 8

      t.deepEqual error.path, ['a[b][c][2]', 'b']
      t.equal error.factory, 'fail'
      t.deepEqual lifetime, {}

      t.end()

  t.test 'object', (t) ->
    source = hinoki.source
      a: [
        -> 'a'
        -> 'b'
        {
          c:
            d: 'fail'
        }
      ]
      b: (a) -> a
    lifetime = {}

    hinoki(source, lifetime, 'b').catch hinoki.BadFactoryError, (error) ->
      t.equal error.name, 'BadFactoryError'
      t.equal error.message, "factory for `a[2][c][d]` has to be a function, object of factories or array of factories but is `string`"
      if Error.captureStackTrace?
        t.equal 'string', typeof error.stack
        t.ok error.stack.split('\n').length > 8

      t.deepEqual error.path, ['a[2][c][d]', 'b']
      t.equal error.factory, 'fail'
      t.deepEqual lifetime, {}

      t.end()
