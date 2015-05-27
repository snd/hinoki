hinoki = require '../src/hinoki'
_ = require 'lodash'

module.exports =

  'arrayOfStringsHasDuplicates': (test) ->
    test.ok not hinoki.arrayOfStringsHasDuplicates []
    test.ok not hinoki.arrayOfStringsHasDuplicates ['a']
    test.ok not hinoki.arrayOfStringsHasDuplicates ['a', 'b']
    test.ok not hinoki.arrayOfStringsHasDuplicates ['a', 'b', 'c']
    test.ok hinoki.arrayOfStringsHasDuplicates ['a', 'a']
    test.ok hinoki.arrayOfStringsHasDuplicates ['a', 'a', 'b']
    test.ok hinoki.arrayOfStringsHasDuplicates ['b', 'a', 'b']
    test.ok hinoki.arrayOfStringsHasDuplicates ['a', 'b', 'b']
    test.done()

  'tryCatch':

    'no error': (test) ->
      fun = (a, b) ->
        test.equal a, 1
        test.equal b, 2
        return a + b
      result = hinoki.tryCatch fun, [1, 2]
      test.ok not _.isError result
      test.equal result, 3
      test.done()

    'return error': (test) ->
      error = new Error 'test'
      fun = (a, b) ->
        test.equal a, 1
        test.equal b, 2
        return error
      result = hinoki.tryCatch fun, [1, 2]
      test.ok _.isError result
      test.equal error, result
      test.done()

    'throw error': (test) ->
      error = new Error 'test'
      fun = (a, b) ->
        test.equal a, 1
        test.equal b, 2
        throw error
      result = hinoki.tryCatch fun, [1, 2]
      test.ok _.isError result
      test.equal error, result
      test.done()

    'throw something': (test) ->
      error = 'test'
      fun = (a, b) ->
        test.equal a, 1
        test.equal b, 2
        throw error
      result = hinoki.tryCatch fun, [1, 2]
      test.ok not _.isError error
      test.ok _.isError result
      test.equal result.message, 'test'
      test.notEqual error, result
      test.done()

  'source':

    'function': (test) ->
      test.expect 2
      result = ->
      source = hinoki.source (name) ->
        test.equal name, 'example'
        return result
      test.equal(source('example'), result)
      test.done()

    'object': (test) ->
      test.expect 2
      result = ->
      source = hinoki.source
        example: result
      test.equal(source('example'), result)
      test.equal(source('missing'), null)
      test.done()

    'path to .js file': (test) ->
      source = hinoki.source "#{__dirname}/a/a.js"
      test.equal source('a')(), 'i am factory a'
      test.equal(source('missing'), null)
      test.done()

    'path to .coffee file': (test) ->
      source = hinoki.source "#{__dirname}/a/b/b.coffee"
      test.equal source('b')(), 'i am factory b'
      test.equal(source('missing'), null)
      test.done()

    'path to folder': (test) ->
      source = hinoki.source "#{__dirname}/a/c"
      test.equal source('c')(), 'i am factory c'
      test.equal(source('a'), null)
      test.equal(source('b'), null)
      test.equal(source('missing'), null)
      test.done()

    'path to nested folder': (test) ->
      source = hinoki.source "#{__dirname}/a"
      test.equal source('a')(), 'i am factory a'
      test.equal source('b')(), 'i am factory b'
      test.equal source('c')(), 'i am factory c'
      test.equal source('d')(), 'i am factory d'
      test.equal(source('missing'), null)
      test.done()

    'array': (test) ->
      e = ->
      f = ->
      g = ->
      source = hinoki.source [
        (name) ->
          if name is 'e'
            return e
        {
          f: f
        }
        "#{__dirname}/a"
        hinoki.source (name) ->
          if name is 'g'
            return g
      ]
      test.equal source('a')(), 'i am factory a'
      test.equal source('b')(), 'i am factory b'
      test.equal source('c')(), 'i am factory c'
      test.equal source('d')(), 'i am factory d'
      test.equal(source('e'), e)
      test.equal(source('f'), f)
      test.equal(source('g'), g)
      test.equal(source('missing'), null)
      test.done()
