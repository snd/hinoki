hinoki = require '../src/hinoki'
_ = require 'lodash'

module.exports =

  'isNull': (test) ->
    test.ok hinoki.isNull null
    test.ok not hinoki.isNull undefined
    test.ok not hinoki.isNull 0
    test.ok not hinoki.isNull false
    test.ok not hinoki.isNull ''

    test.done()

  'isUndefined': (test) ->
    test.ok hinoki.isUndefined undefined
    test.ok not hinoki.isUndefined null
    test.ok not hinoki.isUndefined 0
    test.ok not hinoki.isUndefined false
    test.ok not hinoki.isUndefined ''

    test.done()

  'isExisting': (test) ->
    test.ok hinoki.isExisting {}
    test.ok hinoki.isExisting false
    test.ok hinoki.isExisting 0
    test.ok hinoki.isExisting ''

    test.ok not hinoki.isExisting null
    test.ok not hinoki.isExisting undefined

    test.done()

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

  'coerceToArray': (test) ->
    test.deepEqual [], hinoki.coerceToArray []
    test.deepEqual [1, 2, 3], hinoki.coerceToArray [1, 2, 3]
    test.deepEqual [1], hinoki.coerceToArray 1
    test.deepEqual [], hinoki.coerceToArray null
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

  'parseFunctionArguments': (test) ->
    try
      hinoki.parseFunctionArguments 0
    catch err
      test.equal err.message, 'argument must be a function'
    test.deepEqual [], hinoki.parseFunctionArguments ->
    test.deepEqual ['first'],
      hinoki.parseFunctionArguments (first) ->
    test.deepEqual ['first', 'second'],
      hinoki.parseFunctionArguments (first, second) ->
    test.deepEqual ['first', 'second', 'third'],
      hinoki.parseFunctionArguments (first, second, third) ->
    test.done()

  'getIndexOfFirstObjectHavingProperty': (test) ->
    test.equals null, hinoki.getIndexOfFirstObjectHavingProperty(
      []
      'a'
    )
    test.equals null, hinoki.getIndexOfFirstObjectHavingProperty(
      [{}, {}, {b: 'b'}]
      'a'
    )
    test.equals 0, hinoki.getIndexOfFirstObjectHavingProperty(
      [{a: 'a'}, {}, {b: 'b'}]
      'a'
    )
    test.equals null, hinoki.getIndexOfFirstObjectHavingProperty(
      [{a: undefined}, {}, {b: 'b'}]
      'a'
    )
    test.equals 3, hinoki.getIndexOfFirstObjectHavingProperty(
      [{}, {}, {b: 'b'}, {a: null}]
      'a'
    )
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
