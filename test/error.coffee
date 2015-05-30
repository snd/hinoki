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
      test.equal error.message, "neither value nor factory found for name `a` in path `a`"
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
