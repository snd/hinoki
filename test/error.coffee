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

  'ErrorInResolversError':

    'thrown': (test) ->
      x = new Error 'fail'
      lifetime =
        resolvers: ->
          throw x

      hinoki(lifetime, 'a').catch hinoki.ErrorInResolversError, (error) ->
        test.equal error.name, 'ErrorInResolversError'
        test.equal error.message, "error in resolvers for 'a' (a). original error: Error: fail"
        test.equal 'string', typeof error.stack
        test.ok error.stack.split('\n').length > 8

        test.deepEqual error.path, ['a']
        test.equal error.error, x
        test.ok not lifetime.promisesAwaitingResolution?

        test.done()

    'returned': (test) ->
      x = new Error 'fail'
      lifetime =
        resolvers: ->
          x

      hinoki(lifetime, 'a').catch hinoki.ErrorInResolversError, (error) ->
        test.equal error.message, "error in resolvers for 'a' (a). original error: Error: fail"
        test.deepEqual error.path, ['a']
        test.equal error.error, x
        test.ok not lifetime.promisesAwaitingResolution?
        test.done()

  'UnresolvableError':

    'custom resolver': (test) ->
      lifetime =
        resolvers: ->

      hinoki(lifetime, 'a').catch hinoki.UnresolvableError, (error) ->
        test.equal error.name, 'UnresolvableError'
        test.equal error.message, "unresolvable name 'a' (a)"
        test.equal 'string', typeof error.stack
        test.ok error.stack.split('\n').length > 8

        test.deepEqual error.path, ['a']
        test.ok not lifetime.promisesAwaitingResolution?

        test.done()

    'default resolver': (test) ->
      lifetime = {}

      hinoki(lifetime, 'a').catch hinoki.UnresolvableError, (error) ->
        test.equal error.message, "unresolvable name 'a' (a)"
        test.deepEqual error.path, ['a']
        test.ok not lifetime.promisesAwaitingResolution?
        test.done()

  'resolutionErrors':

    'null value': (test) ->
      errors = hinoki.resolutionErrors
        value: null
        name: 'a'
      test.equal errors, null
      test.done()

    'value': (test) ->
      errors = hinoki.resolutionErrors
        value: {}
        name: 'a'
      test.equal errors, null
      test.done()

    'factory': (test) ->
      errors = hinoki.resolutionErrors
        factory: ->
        name: 'a'
      test.equal errors, null
      test.done()

    'factory nocache': (test) ->
      errors = hinoki.resolutionErrors
        factory: ->
        name: 'a'
        nocache: true
      test.equal errors, null
      test.done()

    'not an object': (test) ->
      errors = hinoki.resolutionErrors()
      test.deepEqual errors, [
        "must be an object"
        "must have the 'name' property which is a string"
        "must have either the 'value' or the 'factory' property"
      ]
      test.done()

    'empty object': (test) ->
      errors = hinoki.resolutionErrors {}
      test.deepEqual errors, [
        "must have the 'name' property which is a string"
        "must have either the 'value' or the 'factory' property"
      ]
      test.done()

    'object with name': (test) ->
      errors = hinoki.resolutionErrors
        name: 'test'
      test.deepEqual errors, [
        "must have either the 'value' or the 'factory' property"
      ]
      test.done()

    'both value and factory': (test) ->
      errors = hinoki.resolutionErrors
        name: 'test'
        value: 1
        factory: 2
      test.deepEqual errors, [
        "must have either the 'value' or the 'factory' property - not both"
      ]
      test.done()

    'factory is not a function': (test) ->
      errors = hinoki.resolutionErrors
        name: 'test'
        factory: 2
      test.deepEqual errors, [
        "the 'factory' property must be a function"
      ]
      test.done()

  'InvalidResolutionError': (test) ->
    resolution =
      factory: 'test'
    lifetime =
      resolvers: ->
        resolution

    hinoki(lifetime, 'a').catch hinoki.InvalidResolutionError, (error) ->
      test.equal error.name, 'InvalidResolutionError'
      lines = [
        "errors in resolution returned by resolvers for 'a' (a):"
        "must have the 'name' property which is a string"
        "the 'factory' property must be a function"
      ]
      test.equal error.message, lines.join('\n')
      test.equal 'string', typeof error.stack
      test.ok error.stack.split('\n').length > 8

      test.equal error.resolution, resolution
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
