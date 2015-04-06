hinoki = require '../src/hinoki'

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
