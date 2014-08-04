hinoki = require '../src/hinoki'

module.exports =

  'return null or undefined': (test) ->
    f = ->
    test.ok not hinoki.isNull f()
    test.ok hinoki.isUndefined f()

    g = -> return
    test.ok not hinoki.isNull g()
    test.ok hinoki.isUndefined g()

    h = -> return undefined
    test.ok not hinoki.isNull h()
    test.ok hinoki.isUndefined h()

    h = -> return null
    test.ok hinoki.isNull h()
    test.ok not hinoki.isUndefined h()

    test.done()

  'properties null or undefined': (test) ->
    a = {}
    test.ok not hinoki.isNull a.test
    test.ok hinoki.isUndefined a.test
    test.ok not hinoki.isNull a['test']
    test.ok hinoki.isUndefined a['test']

    b =
      test: undefined
    test.ok not hinoki.isNull b.test
    test.ok hinoki.isUndefined b.test

    c =
      test: null
    test.ok hinoki.isNull c.test
    test.ok not hinoki.isUndefined c.test

    d =
      test: null
    delete d.test
    test.ok not hinoki.isNull d.test
    test.ok hinoki.isUndefined d.test

    test.done()
