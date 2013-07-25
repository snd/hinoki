q = require 'q'

module.exports =

    parseFunctionArguments: (fun) ->
        unless 'function' is typeof fun
            throw new Error 'argument must be a function'

        string = fun.toString()

        argumentPart = string.slice(string.indexOf('(') + 1, string.indexOf(')'))

        dependencies = argumentPart.split(/,\s/)

        return if dependencies[0] is '' then [] else dependencies

    find: (containers, id) ->
        len = containers.length
        i = 0
        while i < len
            container = containers[i]

            instance = container.instances?[id]
            if instance?
                return {
                    instance: instance
                    containers: containers.slice(i)
                }

            factory = container.factories?[id]
            if factory?
                return {
                    factory: factory
                    containers: containers.slice(i)
                }

            i++

        return null

    inject: (arg, fun) ->
        containers = if Array.isArray arg then arg else [arg]

        containers.forEach (c) ->
            unless c? and 'object' is typeof c
                throw new Error 'the first argument to inject must be an object or an array of objects'

        containers.forEach (c) ->
            unless c.instances?
                c.instances = {}

        dependencyIds = module.exports.parseFunctionArguments fun

        module.exports.resolve containers, dependencyIds, [], ->
            fun.apply null, arguments

    resolve: (containers, dependencyIds, chain, cb) ->
        hasErrorOccured = false
        resolved = {}

        maybeResolved = ->
            if hasErrorOccured
                return
            if Object.keys(resolved).length is dependencyIds.length
                cb.apply null, dependencyIds.map (id) -> resolved[id]

        dependencyIds.forEach (id) ->
            result = module.exports.find containers, id

            unless result?
                throw new Error "missing factory for service '#{id}'"

            if result.instance?
                resolved[id] = result.instance
                return

            newChain = chain.concat([id])

            if id in chain
                throw new Error "circular dependency #{newChain.join(' <- ')}"

            unless 'function' is typeof result.factory
                throw new Error "factory is not a function '#{id}'"

            factoryDependencyIds = module.exports.parseFunctionArguments result.factory

            module.exports.resolve result.containers, factoryDependencyIds, newChain, ->
                try
                    instance = result.factory.apply null, arguments
                catch err
                    throw new Error "exception in factory '#{id}': #{err}"
                unless q.isPromise instance
                    result.containers[0].instances[id] = instance
                    resolved[id] = instance
                    return

                onSuccess = (value) ->
                    result.containers[0].instances[id] = value
                    resolved[id] = value
                    maybeResolved()
                onError = (err) ->
                    hasErrorOccured = true
                    throw new Error "error resolving promise returned from factory '#{id}'"
                instance.done(onSuccess, onError)

        maybeResolved()
