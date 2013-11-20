module.exports =

    # returns first value in `array` for which `predicate` returns true

    find: (array, predicate) ->
        i = 0
        length = array.length
        while i < length
            if predicate array[i]
                return array[i]
            i++
        return null

    # complexity: O(n) since hash lookup is O(1)

    arrayOfStringsHasDuplicates: (array) ->
        i = 0
        length = array.length
        valuesSoFar = {}
        while i < length
            value = array[i]
            if Object.prototype.hasOwnProperty.call valuesSoFar, value
                return true
            valuesSoFar[value] = true
            i++
        return false

    # coerces `arg` into an array.
    #
    # returns `arg` if it is an array.
    # returns `[arg]` otherwise.
    # returns `[]` if `arg` is null.
    #
    # example:
    # arrayify 'a'
    # => ['a']

    arrayify: (arg) ->
        if Array.isArray arg
            return arg
        unless arg?
            return []
        [arg]

    # returns the first sequence of elements in `xs` which starts with `x`
    #
    # example:
    # startingWith ['a', 'b', 'c', 'd'], 'c'
    # => ['c', 'd']

    startingWith: (xs, x) ->
        index = xs.indexOf x
        return [] if index is -1
        xs.slice index

    # example:
    # parseFunctionArguments (a, b c) ->
    # => ['a', 'b‘, 'c']

    parseFunctionArguments: (fun) ->
        unless 'function' is typeof fun
            throw new Error 'argument must be a function'

        string = fun.toString()

        argumentPart = string.slice(string.indexOf('(') + 1, string.indexOf(')'))

        dependencies = argumentPart.match(/([^\s,]+)/g)

        return if dependencies? then dependencies else []
