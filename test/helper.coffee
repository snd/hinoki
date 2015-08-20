test = require 'tape'
_ = require 'lodash'

hinoki = require '../lib/hinoki'

test 'tryCatch', (t) ->

  t.test 'no error', (t) ->
    fun = (a, b) ->
      t.equal a, 1
      t.equal b, 2
      return a + b
    result = hinoki.tryCatch fun, [1, 2]
    t.ok not _.isError result
    t.equal result, 3
    t.end()

  t.test 'return error', (t) ->
    error = new Error 't'
    fun = (a, b) ->
      t.equal a, 1
      t.equal b, 2
      return error
    result = hinoki.tryCatch fun, [1, 2]
    t.ok _.isError result
    t.equal error, result
    t.end()

  t.test 'throw error', (t) ->
    error = new Error 't'
    fun = (a, b) ->
      t.equal a, 1
      t.equal b, 2
      throw error
    result = hinoki.tryCatch fun, [1, 2]
    t.ok _.isError result
    t.equal error, result
    t.end()

  t.test 'throw something', (t) ->
    error = 't'
    fun = (a, b) ->
      t.equal a, 1
      t.equal b, 2
      throw error
    result = hinoki.tryCatch fun, [1, 2]
    t.ok not _.isError error
    t.ok _.isError result
    t.equal result.message, 't'
    t.notEqual error, result
    t.end()

test 'source', (t) ->

  t.test 'function', (t) ->
    t.plan 2
    result = ->
    source = hinoki.source (key) ->
      t.equal key, 'example'
      return result
    t.equal(source('example'), result)
    t.end()

  t.test 'object', (t) ->
    result = ->
    source = hinoki.source
      example: result
    t.equal(source('example'), result)
    t.equal(source('missing'), undefined)
    t.deepEqual source.keys(), ['example']
    t.end()

  t.test 'path to .js file', (t) ->
    source = hinoki.source "#{__dirname}/a/a.js"
    t.equal source('a')(), 'i am factory a'
    t.equal(source('missing'), undefined)
    t.deepEqual source.keys(), ['a']
    t.end()

  t.test 'path to .coffee file', (t) ->
    source = hinoki.source "#{__dirname}/a/b/b.coffee"
    t.equal source('b')(), 'i am factory b'
    t.equal(source('missing'), undefined)
    t.deepEqual source.keys(), ['b']
    t.end()

  t.test 'path to folder', (t) ->
    source = hinoki.source "#{__dirname}/a/c"
    t.equal source('c')(), 'i am factory c'
    t.equal(source('a'), undefined)
    t.equal(source('b'), undefined)
    t.equal(source('missing'), undefined)
    t.deepEqual source.keys(), ['c']
    t.end()

  t.test 'path to nested folder', (t) ->
    source = hinoki.source "#{__dirname}/a"
    t.equal source('a')(), 'i am factory a'
    t.equal source('b')(), 'i am factory b'
    t.equal source('c')(), 'i am factory c'
    t.equal source('d')(), 'i am factory d'
    t.equal(source('missing'), undefined)
    t.deepEqual source.keys(), ['a', 'b', 'd', 'c']
    t.end()

  t.test 'array', (t) ->
    e = ->
    f = ->
    g = ->
    source = hinoki.source [
      (key) ->
        if key is 'e'
          return e
      {
        f: f
      }
      "#{__dirname}/a"
      hinoki.source (key) ->
        if key is 'g'
          return g
    ]
    t.equal source('a')(), 'i am factory a'
    t.equal source('b')(), 'i am factory b'
    t.equal source('c')(), 'i am factory c'
    t.equal source('d')(), 'i am factory d'
    t.equal(source('e'), e)
    t.equal(source('f'), f)
    t.equal(source('g'), g)
    t.equal(source('missing'), null)
    t.deepEqual source.keys(), ['f', 'a', 'b', 'd', 'c']
    t.end()

test 'getKeysToInject', (t) ->

  t.test '__inject', (t) ->
    factory = {}
    factory.__inject = ['a', 'b', 'c']
    t.deepEqual hinoki.getKeysToInject(factory), ['a', 'b', 'c']
    t.end()

  t.test 'function', (t) ->
    factory = (d, e, f) ->
    t.deepEqual hinoki.getKeysToInject(factory), ['d', 'e', 'f']
    t.end()

  t.test 'object', (t) ->
    factory =
      a: ->
      b: (a, b) ->
      c: (a, c, d) ->
    factory.a.__inject = ['a', 'b', 'c']
    t.deepEqual hinoki.getKeysToInject(factory), ['a', 'b', 'c', 'd']
    t.end()

  t.test 'array', (t) ->
    factory = [
      ->
      (a, b) ->
      (c, d) ->
    ]
    factory[0].__inject = ['a', 'b', 'c']
    t.deepEqual hinoki.getKeysToInject(factory), ['a', 'b', 'c', 'd']
    t.end()
