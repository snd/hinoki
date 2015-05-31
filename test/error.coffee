Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'errors can be catched as BaseError': (test) ->
    source = hinoki.source
      a: ->
    lifetime = {}

    hinoki(source, lifetime, 'a').catch hinoki.BaseError, (error) ->
      test.equal error.name, 'FactoryReturnedUndefinedError'
      test.done()

  'NotFoundError': (test) ->
    source = ->
    lifetime = {}

    hinoki(source, lifetime, 'a').catch hinoki.NotFoundError, (error) ->
      test.equal error.message, "neither value nor factory found for `a` in path `a`"
      test.deepEqual error.path, ['a']
      test.done()

  'CircularDependencyError':
    '2': (test) ->
      source = hinoki.source
        a: (a) ->
      lifetime = {}

      hinoki(source, lifetime, 'a').catch hinoki.CircularDependencyError, (error) ->
        test.equal error.name, 'CircularDependencyError'
        test.equal error.message, "circular dependency `a <- a`"
        test.equal 'string', typeof error.stack
        test.ok error.stack.split('\n').length > 8

        test.deepEqual error.path, ['a', 'a']
        test.deepEqual lifetime, {}

        test.done()

    '3': (test) ->
      source = hinoki.source
        a: (b) ->
        b: (a) ->
      lifetime = {}

      hinoki(source, lifetime, 'a').catch hinoki.CircularDependencyError, (error) ->
        test.equal error.name, 'CircularDependencyError'
        test.equal error.message, "circular dependency `a <- b <- a`"
        test.equal 'string', typeof error.stack
        test.ok error.stack.split('\n').length > 8

        test.deepEqual error.path, ['a', 'b', 'a']
        test.deepEqual lifetime, {}

        test.done()

  'ErrorInFactory': (test) ->
    exception = new Error 'fail'
    a = -> throw exception

    source = hinoki.source
      a: a
    lifetime = {}

    hinoki(source, lifetime, 'a').catch hinoki.ErrorInFactory, (error) ->
      test.equal error.name, 'ErrorInFactory'
      test.equal error.message, "error in factory for `a`. original error `Error: fail`"
      test.equal 'string', typeof error.stack
      test.ok error.stack.split('\n').length > 8

      test.deepEqual error.path, ['a']
      test.equal error.factory, a
      test.equal error.error, exception
      test.deepEqual lifetime, {}

      test.done()

  'FactoryReturnedUndefinedError': (test) ->
    a = ->
    source = hinoki.source
      a: a
    lifetime = {}

    hinoki(source, lifetime, 'a').catch hinoki.FactoryReturnedUndefinedError, (error) ->
      test.equal error.name, 'FactoryReturnedUndefinedError'
      test.equal error.message, "factory for `a` returned undefined"
      test.equal 'string', typeof error.stack
      test.ok error.stack.split('\n').length > 8

      test.deepEqual error.path, ['a']
      test.equal error.factory, a
      test.deepEqual lifetime, {}

      test.done()

  'PromiseRejectedError and that errored promises are removed': (test) ->
    rejection = new Error 'fail'
    a = -> Promise.reject rejection

    source = hinoki.source
      a: a
    lifetime = {}

    hinoki(source, lifetime, 'a').catch hinoki.PromiseRejectedError, (error) ->
      test.equal error.name, 'PromiseRejectedError'
      test.equal error.message, "promise returned from factory for `a` was rejected. original error `Error: fail`"
      test.equal 'string', typeof error.stack
      test.ok error.stack.split('\n').length > 8

      test.deepEqual error.path, ['a']
      test.equal error.error, rejection
      test.equal error.factory, a
      test.deepEqual lifetime, {}

      test.done()

  'BadFactoryError':

    'flat': (test) ->
      source = hinoki.source
        a: 1
      lifetime = {}

      hinoki(source, lifetime, 'a').catch hinoki.BadFactoryError, (error) ->
        test.equal error.name, 'BadFactoryError'
        test.equal error.message, "factory for `a` has to be a function, object of factories or array of factories but is `number`"
        test.equal 'string', typeof error.stack
        test.ok error.stack.split('\n').length > 8

        test.deepEqual error.path, ['a']
        test.equal error.factory, 1
        test.deepEqual lifetime, {}

        test.done()

    'array': (test) ->
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
        test.equal error.name, 'BadFactoryError'
        test.equal error.message, "factory for `a[b][c][2]` has to be a function, object of factories or array of factories but is `string`"
        test.equal 'string', typeof error.stack
        test.ok error.stack.split('\n').length > 8

        test.deepEqual error.path, ['a[b][c][2]', 'b']
        test.equal error.factory, 'fail'
        test.deepEqual lifetime, {}

        test.done()

    'object': (test) ->
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
        test.equal error.name, 'BadFactoryError'
        test.equal error.message, "factory for `a[2][c][d]` has to be a function, object of factories or array of factories but is `string`"
        test.equal 'string', typeof error.stack
        test.ok error.stack.split('\n').length > 8

        test.deepEqual error.path, ['a[2][c][d]', 'b']
        test.equal error.factory, 'fail'
        test.deepEqual lifetime, {}

        test.done()
