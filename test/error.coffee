Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'errors can be catched as BaseError': (test) ->
    lifetime =
      factories:
        a: ->

    hinoki(lifetime, 'a').catch hinoki.BaseError, (error) ->
      test.equal error.name, 'FactoryReturnedUndefinedError'
      test.done()

  'UnresolvableError': (test) ->
    lifetime = {}

    hinoki(lifetime, 'a').catch hinoki.UnresolvableError, (error) ->
      test.equal error.message, "unresolvable name 'a' (a)"
      test.deepEqual error.path, ['a']
      test.ok not lifetime.promisesAwaitingResolution?
      test.done()

  'CircularDependencyError': (test) ->
    lifetime =
      factories:
        a: (a) ->

    hinoki(lifetime, 'a').catch hinoki.CircularDependencyError, (error) ->
      test.equal error.name, 'CircularDependencyError'
      test.equal error.message, "circular dependency a <- a"
      test.equal 'string', typeof error.stack
      test.ok error.stack.split('\n').length > 8

      test.deepEqual error.path, ['a', 'a']
      test.equal error.lifetime, lifetime
      test.equal error.factory, lifetime.factories.a
      test.ok not lifetime.promisesAwaitingResolution?

      test.done()

  'ThrowInFactoryError': (test) ->
    exception = new Error 'fail'

    lifetime =
      factories:
        a: -> throw exception

    hinoki(lifetime, 'a').catch hinoki.ThrowInFactoryError, (error) ->
      test.equal error.name, 'ThrowInFactoryError'
      test.equal error.message, "error in factory for 'a'. original error: Error: fail"
      test.equal 'string', typeof error.stack
      test.ok error.stack.split('\n').length > 8

      test.deepEqual error.path, ['a']
      test.equal error.lifetime, lifetime
      test.equal error.factory, lifetime.factories.a
      test.equal error.error, exception
      test.ok not lifetime.promisesAwaitingResolution?

      test.done()

  'FactoryReturnedUndefinedError': (test) ->
    lifetime =
      factories:
        a: ->

    hinoki(lifetime, 'a').catch hinoki.FactoryReturnedUndefinedError, (error) ->
      test.equal error.name, 'FactoryReturnedUndefinedError'
      test.equal error.message, "factory for 'a' returned undefined"
      test.equal 'string', typeof error.stack
      test.ok error.stack.split('\n').length > 8

      test.deepEqual error.path, ['a']
      test.equal error.lifetime, lifetime
      test.ok not lifetime.promisesAwaitingResolution?

      test.done()

  'PromiseRejectedError': (test) ->
    rejection = new Error 'fail'

    lifetime =
      factories:
        a: -> Promise.reject rejection

    hinoki(lifetime, 'a').catch hinoki.PromiseRejectedError, (error) ->
      test.equal error.name, 'PromiseRejectedError'
      test.equal error.message, "promise returned from factory for 'a' was rejected. original error: Error: fail"
      test.equal 'string', typeof error.stack
      test.ok error.stack.split('\n').length > 8

      test.deepEqual error.path, ['a']
      test.equal error.lifetime, lifetime
      test.equal error.error, rejection
      test.ok not lifetime.promisesAwaitingResolution?

      test.done()
