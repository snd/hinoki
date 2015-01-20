Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'ErrorInResolversError':

    'thrown': (test) ->
      test.expect 4
      x = new Error 'fail'
      c =
        resolvers: ->
          throw x

      hinoki.get(c, 'a').catch hinoki.ErrorInResolversError, (error) ->
        test.equal error.message, "error in resolvers for 'a' (a). original error: Error: fail"
        test.deepEqual error.path, ['a']
        test.equal error.error, x
        test.ok not c.promisesAwaitingResolution?
        test.done()

    'returned': (test) ->
      test.expect 4
      x = new Error 'fail'
      c =
        resolvers: ->
          x

      hinoki.get(c, 'a').catch hinoki.ErrorInResolversError, (error) ->
        test.equal error.message, "error in resolvers for 'a' (a). original error: Error: fail"
        test.deepEqual error.path, ['a']
        test.equal error.error, x
        test.ok not c.promisesAwaitingResolution?
        test.done()

  'UnresolvableError':

    'custom resolver': (test) ->
      test.expect 3

      c =
        resolvers: ->

      hinoki.get(c, 'a').catch hinoki.UnresolvableError, (error) ->
        test.equal error.message, "unresolvable name 'a' (a)"
        test.deepEqual error.path, ['a']
        test.ok not c.promisesAwaitingResolution?
        test.done()

    'default resolver': (test) ->
      test.expect 3

      c = {}

      hinoki.get(c, 'a').catch hinoki.UnresolvableError, (error) ->
        test.equal error.message, "unresolvable name 'a' (a)"
        test.deepEqual error.path, ['a']
        test.ok not c.promisesAwaitingResolution?
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
    test.expect 4
    resolution =
      factory: 'test'
    c =
      resolvers: ->
        resolution

    hinoki.get(c, 'a').catch hinoki.InvalidResolutionError, (error) ->
      lines = [
        "errors in resolution returned by resolvers for 'a' (a):"
        "must have the 'name' property which is a string"
        "the 'factory' property must be a function"
      ]
      test.equal error.message, lines.join('\n')
      test.equal error.resolution, resolution
      test.deepEqual error.path, ['a']
      test.ok not c.promisesAwaitingResolution?
      test.done()

  'CircularDependencyError': (test) ->
    test.expect 3

    c =
      factories:
        a: (a) ->

    hinoki.get(c, 'a').catch hinoki.CircularDependencyError, (error) ->
      test.equal error.message, "circular dependency a <- a"
      test.deepEqual error.path, ['a', 'a']
      test.ok not c.promisesAwaitingResolution?
      test.done()

  'ThrowInFactoryError': (test) ->
    test.expect 5

    exception = new Error 'fail'

    c =
      factories:
        a: -> throw exception

    hinoki.get(c, 'a').catch hinoki.ThrowInFactoryError, (error) ->
      test.equal error.message, "error in factory for 'a'. original error: Error: fail"
      test.deepEqual error.path, ['a']
      test.equal error.container, c
      test.equal error.error, exception
      test.ok not c.promisesAwaitingResolution?
      test.done()

  'FactoryReturnedUndefinedError': (test) ->
    test.expect 4

    c =
      factories:
        a: ->

    hinoki.get(c, 'a').catch hinoki.FactoryReturnedUndefinedError, (error) ->
      test.equal error.message, "factory for 'a' returned undefined"
      test.deepEqual error.path, ['a']
      test.equal error.container, c
      test.ok not c.promisesAwaitingResolution?
      test.done()

  'PromiseRejectedError': (test) ->
    test.expect 5

    rejection = new Error 'fail'

    c =
      factories:
        a: -> Promise.reject rejection

    hinoki.get(c, 'a').catch hinoki.PromiseRejectedError, (error) ->
      test.equal error.message, "promise returned from factory for 'a' was rejected. original error: Error: fail"
      test.deepEqual error.path, ['a']
      test.equal error.container, c
      test.equal error.error, rejection
      test.ok not c.promisesAwaitingResolution?
      test.done()
