module.exports =

    parseFunctionArguments: (fun) ->
        unless 'function' is typeof fun
            throw new Error 'argument must be a function'

        string = fun.toString()

        argumentPart = string.slice(string.indexOf('(') + 1, string.indexOf(')'))

        dependencies = argumentPart.split(/,\s/)

        return if dependencies[0] is '' then [] else dependencies

    inject: (container, fun, chain = []) ->
        unless container.scope?
            container.scope = {}

        dependencyIds = module.exports.parseFunctionArguments fun

        dependencyIds.forEach (id) ->
            unless container.scope[id]?
                newChain = chain.concat([id])
                if id in chain
                    throw new Error "circular dependency #{newChain.join(' <- ')}"
                factory = container.factories?[id]
                unless factory?
                    throw new Error "missing factory for service '#{id}'"
                container.scope[id] = module.exports.inject container, factory, newChain

        fun.apply null, dependencyIds.map (id) -> container.scope[id]
