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

  'some':

    'array': (test) ->
      test.ok hinoki.isUndefined hinoki.some []

      test.equals 1, hinoki.some [1, null, null]
      test.equals 2, hinoki.some [null, null, 2]

      test.done()

    'array and predicate': (test) ->
      test.ok hinoki.isUndefined hinoki.some [], hinoki.identity, -> true
      test.equals 1, hinoki.some [1], hinoki.identity, (x) -> x is 1
      test.ok hinoki.isUndefined hinoki.some [1], hinoki.identity, (x) -> x is 2
      test.equals 2, hinoki.some [1, 2, 3], hinoki.identity, (x) -> x > 1
      test.ok hinoki.isUndefined hinoki.some [1, 2, 3], hinoki.identity, (x) -> x > 3
      test.ok hinoki.isUndefined hinoki.some [1, 2, 3], hinoki.identity, (x) -> x > 3

      shouldBeNull = hinoki.some [1, 2, null], hinoki.identity, (x) -> x is null
      test.ok not hinoki.isUndefined shouldBeNull
      test.ok hinoki.isNull shouldBeNull

      test.done()

    'array, predicate, transform and sentinel': (test) ->
      test.equals 'sentinel',
          hinoki.some [], hinoki.identity, hinoki.exists, 'sentinel'

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

  'startingWith': (test) ->
    test.deepEqual [], hinoki.startingWith [], 1
    test.deepEqual [], hinoki.startingWith [1], 2
    test.deepEqual [], hinoki.startingWith [1, 2, 3], 4
    test.deepEqual [1, 2, 3], hinoki.startingWith [1, 2, 3], 1
    test.deepEqual [2, 3], hinoki.startingWith [1, 2, 3], 2
    test.deepEqual [3], hinoki.startingWith [1, 2, 3], 3
    test.done()

  'parseFunctionArguments': (test) ->
    try
      hinoki.parseFunctionArguments 0
    catch err
      test.equals err.message, 'argument must be a function'
    test.deepEqual [], hinoki.parseFunctionArguments ->
    test.deepEqual ['first'],
      hinoki.parseFunctionArguments (first) ->
    test.deepEqual ['first', 'second'],
      hinoki.parseFunctionArguments (first, second) ->
    test.deepEqual ['first', 'second', 'third'],
      hinoki.parseFunctionArguments (first, second, third) ->
    test.done()
