common = require '../src/common'

module.exports =

    'find': (test) ->
        test.equals null, common.find [], -> true
        test.equals 1, common.find [1], (x) -> x is 1
        test.equals null, common.find [1], (x) -> x is 2
        test.equals 2, common.find [1, 2, 3], (x) -> x > 1
        test.equals null, common.find [1, 2, 3], (x) -> x > 3
        test.done()

    'arrayOfStringsHasDuplicates': (test) ->
        test.ok not common.arrayOfStringsHasDuplicates []
        test.ok not common.arrayOfStringsHasDuplicates ['a']
        test.ok not common.arrayOfStringsHasDuplicates ['a', 'b']
        test.ok not common.arrayOfStringsHasDuplicates ['a', 'b', 'c']
        test.ok common.arrayOfStringsHasDuplicates ['a', 'a']
        test.ok common.arrayOfStringsHasDuplicates ['a', 'a', 'b']
        test.ok common.arrayOfStringsHasDuplicates ['b', 'a', 'b']
        test.ok common.arrayOfStringsHasDuplicates ['a', 'b', 'b']
        test.done()

    'arrayify': (test) ->
        test.deepEqual [], common.arrayify []
        test.deepEqual [1, 2, 3], common.arrayify [1, 2, 3]
        test.deepEqual [1], common.arrayify 1
        test.deepEqual [], common.arrayify null
        test.done()

    'startingWith': (test) ->
        test.deepEqual [], common.startingWith [], 1
        test.deepEqual [], common.startingWith [1], 2
        test.deepEqual [], common.startingWith [1, 2, 3], 4
        test.deepEqual [1, 2, 3], common.startingWith [1, 2, 3], 1
        test.deepEqual [2, 3], common.startingWith [1, 2, 3], 2
        test.deepEqual [3], common.startingWith [1, 2, 3], 3
        test.done()

    'parseFunctionArguments': (test) ->
        try
            common.parseFunctionArguments 0
        catch err
            test.equals err.message, 'argument must be a function'
        test.deepEqual [], common.parseFunctionArguments ->
        test.deepEqual ['first'],
            common.parseFunctionArguments (first) ->
        test.deepEqual ['first', 'second'],
            common.parseFunctionArguments (first, second) ->
        test.deepEqual ['first', 'second', 'third'],
            common.parseFunctionArguments (first, second, third) ->
        test.done()
