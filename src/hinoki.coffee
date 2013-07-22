module.exports =

    parseDependencies: (fun) ->
        unless 'function' is typeof fun
            throw new Error 'argument must be a function'

        string = fun.toString()

        argumentPart = string.slice(string.indexOf('(') + 1, string.indexOf(')'))

        dependencies = argumentPart.split(/,\s/)

        return if dependencies[0] is '' then [] else dependencies
