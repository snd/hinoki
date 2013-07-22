module.exports =

    parseDependencies: (fun) ->
        unless 'function' is typeof fun
            throw new Error 'argument must be a function'
