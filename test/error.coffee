Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'CircularDependencyError': (test) ->
    test.expect 3

    c = hinoki.newContainer
      a: (a) ->

    hinoki.get(c, 'a').catch hinoki.CircularDependencyError, (error) ->
      test.equals error.type, 'CircularDependencyError'
      test.deepEqual error.path, ['a', 'a']
      test.equals error.container, c
      test.done()

  'UnresolvableFactoryError': (test) ->
    test.expect 3

    c = hinoki.newContainer()

    hinoki.get(c, 'a').catch hinoki.UnresolvableFactoryError, (error) ->
      test.equals error.type, 'UnresolvableFactoryError'
      test.deepEqual error.path, ['a']
      test.equals error.container, c
      test.done()

  'ExceptionInFactoryError': (test) ->
    test.expect 4

    exception = {}

    c = hinoki.newContainer
      a: -> throw exception

    hinoki.get(c, 'a').catch hinoki.ExceptionInFactoryError, (error) ->
      test.equals error.type, 'ExceptionInFactoryError'
      test.deepEqual error.path, ['a']
      test.equals error.container, c
      test.equals error.exception, exception
      test.done()

  'PromiseRejectedError': (test) ->
    test.expect 4

    rejection = {}

    c = hinoki.newContainer
      a: -> Promise.reject rejection

    hinoki.get(c, 'a').catch hinoki.PromiseRejectedError, (error) ->
      test.equals error.type, 'PromiseRejectedError'
      test.deepEqual error.path, ['a']
      test.equals error.container, c
      test.equals error.rejection, rejection
      test.done()

  'FactoryNotFunctionError': (test) ->
    test.expect 4

    factory = {}

    c = hinoki.newContainer
      a: factory

    hinoki.get(c, 'a').catch hinoki.FactoryNotFunctionError, (error) ->
      test.equals error.type, 'FactoryNotFunctionError'
      test.deepEqual error.path, ['a']
      test.equals error.container, c
      test.equals error.factory, factory
      test.done()

  'FactoryReturnedUndefinedError': (test) ->
    test.expect 3

    c = hinoki.newContainer
      a: ->

    hinoki.get(c, 'a').catch hinoki.FactoryReturnedUndefinedError, (error) ->
      test.equals error.type, 'FactoryReturnedUndefinedError'
      test.deepEqual error.path, ['a']
      test.equals error.container, c
      test.done()
