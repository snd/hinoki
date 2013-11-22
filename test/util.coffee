util = require '../src/util'

module.exports =

    'find': (test) ->
        test.equals null, util.find [], -> true
        test.equals 1, util.find [1], (x) -> x is 1
        test.equals null, util.find [1], (x) -> x is 2
        test.equals 2, util.find [1, 2, 3], (x) -> x > 1
        test.equals null, util.find [1, 2, 3], (x) -> x > 3
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

    'selectKeys': (test) ->
        test.deepEqual {}, util.selectKeys {a: 1, b: 2, c: 3}, []
        test.deepEqual {a: 1, b: 2}, util.selectKeys {a: 1, b: 2, c: 3}, ['a', 'b']
        test.done()
