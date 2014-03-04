module.exports.isObject = (x) ->
    x is Object(x)

module.exports.isThenable = (x) ->
    module.exports.isObject(x) and 'function' is typeof x.then

module.exports.isUndefined =  (x) ->
    'undefined' is typeof x

module.exports.isNull = (x) ->
    null is x

module.exports.isExisting = (x) ->
    x?

module.exports.identity = (x) ->
    x

# calls fun for the values in array. returns the first
# value returned by transform for which predicate returns true.
# otherwise returns sentinel.

module.exports.some = (
    array,
    iterator = module.exports.identity
    predicate = module.exports.isExisting
    sentinel = undefined
) ->
    i = 0
    length = array.length
    while i < length
        result = iterator array[i]
        if predicate result
            return result
        i++
    return sentinel

# returns whether an array of strings contains duplicates.
#
# complexity: O(n) since hash lookup is O(1)

module.exports.arrayOfStringsHasDuplicates = (array) ->
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

module.exports.arrayify = (arg) ->
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

module.exports.startingWith = (xs, x) ->
    index = xs.indexOf x
    return [] if index is -1
    xs.slice index

# example:
# parseFunctionArguments (a, b c) ->
# => ['a', 'b‘, 'c']

module.exports.parseFunctionArguments = (fun) ->
    unless 'function' is typeof fun
        throw new Error 'argument must be a function'

    string = fun.toString()

    argumentPart = string.slice(string.indexOf('(') + 1, string.indexOf(')'))

    dependencies = argumentPart.match(/([^\s,]+)/g)

    return if dependencies? then dependencies else []

module.exports.merge = (objects...) ->
    result = {}

    objects.forEach (object) ->
        Object.keys(object).forEach (key) ->
            result[key] = object[key]

    return result
