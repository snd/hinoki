util = require '../src/util'

module.exports =

  'isNull': (test) ->
    test.ok util.isNull null
    test.ok not util.isNull undefined
    test.ok not util.isNull 0
    test.ok not util.isNull false
    test.ok not util.isNull ''

    test.done()

  'isUndefined': (test) ->
    test.ok util.isUndefined undefined
    test.ok not util.isUndefined null
    test.ok not util.isUndefined 0
    test.ok not util.isUndefined false
    test.ok not util.isUndefined ''

    test.done()

  'isExisting': (test) ->
    test.ok util.isExisting {}
    test.ok util.isExisting false
    test.ok util.isExisting 0
    test.ok util.isExisting ''

    test.ok not util.isExisting null
    test.ok not util.isExisting undefined

    test.done()

  'some':

    'array': (test) ->
      test.ok util.isUndefined util.some []

      test.equals 1, util.some [1, null, null]
      test.equals 2, util.some [null, null, 2]

      test.done()

    'array and predicate': (test) ->
      test.ok util.isUndefined util.some [], util.identity, -> true
      test.equals 1, util.some [1], util.identity, (x) -> x is 1
      test.ok util.isUndefined util.some [1], util.identity, (x) -> x is 2
      test.equals 2, util.some [1, 2, 3], util.identity, (x) -> x > 1
      test.ok util.isUndefined util.some [1, 2, 3], util.identity, (x) -> x > 3
      test.ok util.isUndefined util.some [1, 2, 3], util.identity, (x) -> x > 3

      shouldBeNull = util.some [1, 2, null], util.identity, (x) -> x is null
      test.ok not util.isUndefined shouldBeNull
      test.ok util.isNull shouldBeNull

      test.done()

    'array, predicate, transform and sentinel': (test) ->
      test.equals 'sentinel',
          util.some [], util.identity, util.exists, 'sentinel'

      test.done()

  'arrayOfStringsHasDuplicates': (test) ->
    test.ok not util.arrayOfStringsHasDuplicates []
    test.ok not util.arrayOfStringsHasDuplicates ['a']
    test.ok not util.arrayOfStringsHasDuplicates ['a', 'b']
    test.ok not util.arrayOfStringsHasDuplicates ['a', 'b', 'c']
    test.ok util.arrayOfStringsHasDuplicates ['a', 'a']
    test.ok util.arrayOfStringsHasDuplicates ['a', 'a', 'b']
    test.ok util.arrayOfStringsHasDuplicates ['b', 'a', 'b']
    test.ok util.arrayOfStringsHasDuplicates ['a', 'b', 'b']
    test.done()

  'arrayify': (test) ->
    test.deepEqual [], util.arrayify []
    test.deepEqual [1, 2, 3], util.arrayify [1, 2, 3]
    test.deepEqual [1], util.arrayify 1
    test.deepEqual [], util.arrayify null
    test.done()

  'startingWith': (test) ->
    test.deepEqual [], util.startingWith [], 1
    test.deepEqual [], util.startingWith [1], 2
    test.deepEqual [], util.startingWith [1, 2, 3], 4
    test.deepEqual [1, 2, 3], util.startingWith [1, 2, 3], 1
    test.deepEqual [2, 3], util.startingWith [1, 2, 3], 2
    test.deepEqual [3], util.startingWith [1, 2, 3], 3
    test.done()

  'parseFunctionArguments': (test) ->
    try
      util.parseFunctionArguments 0
    catch err
      test.equals err.message, 'argument must be a function'
    test.deepEqual [], util.parseFunctionArguments ->
    test.deepEqual ['first'],
      util.parseFunctionArguments (first) ->
    test.deepEqual ['first', 'second'],
      util.parseFunctionArguments (first, second) ->
    test.deepEqual ['first', 'second', 'third'],
      util.parseFunctionArguments (first, second, third) ->
    test.done()
