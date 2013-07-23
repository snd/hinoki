module.exports =

    parseFunctionArguments: (fun) ->
        unless 'function' is typeof fun
            throw new Error 'argument must be a function'

        string = fun.toString()

        argumentPart = string.slice(string.indexOf('(') + 1, string.indexOf(')'))

        dependencies = argumentPart.split(/,\s/)

        return if dependencies[0] is '' then [] else dependencies

    inject: (container, fun) ->
        unless container.scope?
            container.scope = {}

        dependencyIds = module.exports.parseFunctionArguments fun

        module.exports.resolve container, dependencyIds, (err) ->

            fun.apply null, dependencyIds.map (id) -> container.scope[id]

    resolve: (container, dependencyIds, cb) ->
        dependencyIds.forEach (id) ->
            unless container.scope[id]?
                factory = container.factories?[id]
                unless factory?
                    throw new Error "missing factory for service '#{id}'"
                container.scope[id] = module.exports.inject container, factory
        cb()
