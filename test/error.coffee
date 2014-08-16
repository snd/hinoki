Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'CircularDependencyError': (test) ->
    c =
      factories:
        a: (a) ->

    hinoki.get(c, 'a').catch hinoki.CircularDependencyError, (error) ->
      test.equal error.type, 'CircularDependencyError'
      test.deepEqual error.path, ['a', 'a']
      test.equal error.container, c
      test.done()

  'UnresolvableFactoryError': (test) ->
    test.expect 3

    c = {}

    hinoki.get(c, 'a').catch hinoki.UnresolvableFactoryError, (error) ->
      test.equal error.type, 'UnresolvableFactoryError'
      test.deepEqual error.path, ['a']
      test.equal error.container, c
      test.done()

  'ExceptionInFactoryError': (test) ->
    test.expect 4

    exception = {}

    c =
      factories:
        a: -> throw exception

    hinoki.get(c, 'a').catch hinoki.ExceptionInFactoryError, (error) ->
      test.equal error.type, 'ExceptionInFactoryError'
      test.deepEqual error.path, ['a']
      test.equal error.container, c
      test.equal error.exception, exception
      test.done()

  'PromiseRejectedError': (test) ->
    test.expect 4

    rejection = {}

    c =
      factories:
        a: -> Promise.reject rejection

    hinoki.get(c, 'a').catch hinoki.PromiseRejectedError, (error) ->
      test.equal error.type, 'PromiseRejectedError'
      test.deepEqual error.path, ['a']
      test.equal error.container, c
      test.equal error.rejection, rejection
      test.done()

  'FactoryNotFunctionError': (test) ->
    test.expect 4

    factory = {}

    c =
      factories:
        a: factory

    hinoki.get(c, 'a').catch hinoki.FactoryNotFunctionError, (error) ->
      test.equal error.type, 'FactoryNotFunctionError'
      test.deepEqual error.path, ['a']
      test.equal error.container, c
      test.equal error.factory, factory
      test.done()

  'FactoryReturnedUndefinedError': (test) ->
    test.expect 3

    c =
      factories:
        a: ->

    hinoki.get(c, 'a').catch hinoki.FactoryReturnedUndefinedError, (error) ->
      test.equal error.type, 'FactoryReturnedUndefinedError'
      test.deepEqual error.path, ['a']
      test.equal error.container, c
      test.done()

  'exception in resolver': (test) ->
    test.expect 1

    exception = {}

    c =
      resolvers: [
        -> throw exception
      ]

    hinoki.get(c, 'a').catch (error) ->
      test.equal error, exception
      test.done()
