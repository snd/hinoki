q = require 'q'

hooks = require './hooks'

module.exports =

    parseFunctionArguments: (fun) ->
        unless 'function' is typeof fun
            throw new Error 'argument must be a function'

        string = fun.toString()

        argumentPart = string.slice(string.indexOf('(') + 1, string.indexOf(')'))

        dependencies = argumentPart.match(/([^\s,]+)/g)

        return if dependencies? then dependencies else []

    # find the first instance or factory of the node
    # specified by `id` in `containers`
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

    handleInjectArguments: (arg1, arg2, arg3) ->
        object = {}
        object.containers = if Array.isArray arg1 then arg1 else [arg1]

        object.containers.forEach (c) ->
            unless c? and 'object' is typeof c
                throw new Error 'the 1st argument to inject must be an object or an array of objects'

        object.containers.forEach (c) ->
            unless c.instances?
                c.instances = {}

        if arg3?
            unless 'function' is typeof arg3
                throw new Error 'the 3rd argument to inject is optional but must be a function if provided'
            object.ids = if Array.isArray arg2 then arg2 else [arg2]
            object.ids.forEach (id) ->
                unless id? and 'string' is typeof id
                    throw new Error 'the 2nd argument to inject must be a string or an array of strings if a 3rd argument is provided'
            object.fun = arg3

        else
            unless 'function' is typeof arg2
                throw new Error 'the 2nd argument to inject must be a function if no 3rd argument is provided'
            object.ids = module.exports.parseFunctionArguments arg2
            object.fun = arg2

        object

    inject: ->
        namedArgs = module.exports.handleInjectArguments.apply null, arguments

        module.exports.resolve namedArgs.containers, namedArgs.ids, [], ->
            namedArgs.fun.apply null, arguments

    resolve: (containers, dependencyIds, chain, cb) ->
        hasErrorOccured = false
        resolved = {}

        maybeResolved = ->
            if hasErrorOccured
                return
            if Object.keys(resolved).length is dependencyIds.length
                cb.apply null, dependencyIds.map (id) -> resolved[id]

        dependencyIds.forEach (id) ->
            if hasErrorOccured
                return

            result = module.exports.find containers, id

            newChain = [id].concat chain

            unless result?
                hasErrorOccured = true
                (if containers[0].hooks?.notFound? then containers[0].hooks?.notFound else hooks.notFound) newChain
                return

            container = result.containers[0]

            if result.instance?
                container.hooks?.instanceFound? newChain, result.instance
                resolved[id] = result.instance
                return

            if id in chain
                hasErrorOccured = true
                (if container.hooks?.circle? then container.hooks?.circle else hooks.circle) newChain
                return

            unless 'function' is typeof result.factory
                hasErrorOccured = true
                (if container.hooks?.notFunction? then container.hooks?.notFunction else hooks.notFunction) newChain, result.factory
                return

            factoryDependencyIds = module.exports.parseFunctionArguments result.factory

            container.hooks?.factoryFound? newChain, result.factory, factoryDependencyIds

            module.exports.resolve result.containers, factoryDependencyIds, newChain, ->
                if hasErrorOccured
                    return
                try
                    container.hooks?.factory? newChain, result.factory, Array.prototype.slice.call arguments
                    instance = result.factory.apply null, arguments
                catch err
                    hasErrorOccured = true
                    (if container.hooks?.exception? then container.hooks?.exception else hooks.exception) newChain, err
                    return

                unless q.isPromise instance
                    container.hooks?.instance? newChain, instance
                    container.instances[id] = instance
                    resolved[id] = instance
                    return maybeResolved()

                container.hooks?.promise? newChain, instance

                onSuccess = (value) ->
                    container.hooks?.resolution? newChain, value
                    result.containers[0].instances[id] = value
                    resolved[id] = value
                    maybeResolved()
                onError = (err) ->
                    hasErrorOccured = true
                    (if container.hooks?.rejection? then container.hooks?.rejection else hooks.rejection) newChain, err
                instance.done(onSuccess, onError)

        maybeResolved()
