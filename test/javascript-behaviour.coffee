Promise = require 'bluebird'
helfer = require 'helfer'

hinoki = require '../src/hinoki'

module.exports =

  'return null or undefined': (test) ->
    f = ->
    test.ok not helfer.isNull f()
    test.ok helfer.isUndefined f()

    g = -> return
    test.ok not helfer.isNull g()
    test.ok helfer.isUndefined g()

    h = -> return undefined
    test.ok not helfer.isNull h()
    test.ok helfer.isUndefined h()

    h = -> return null
    test.ok helfer.isNull h()
    test.ok not helfer.isUndefined h()

    test.done()

  'properties null or undefined': (test) ->
    a = {}
    test.ok not helfer.isNull a.test
    test.ok helfer.isUndefined a.test
    test.ok not helfer.isNull a['test']
    test.ok helfer.isUndefined a['test']

    b =
      test: undefined
    test.ok not helfer.isNull b.test
    test.ok helfer.isUndefined b.test

    c =
      test: null
    test.ok helfer.isNull c.test
    test.ok not helfer.isUndefined c.test

    d =
      test: null
    delete d.test
    test.ok not helfer.isNull d.test
    test.ok helfer.isUndefined d.test

    test.done()

  'promise null or undefined': (test) ->
    Promise.resolve().then (v) ->
      test.ok not helfer.isNull v
      test.ok helfer.isUndefined v

      test.done()
