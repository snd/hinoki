events = require 'events'

Promise = require 'bluebird'

# the functions are isolated to be tested in isolation

checkDeps = (deps, names...) ->
    names.map (name) ->
        unless deps[name]?
            throw new Error "missing dependency #{name}"

isObject = (x) ->
    x is Object(x)

isThenable = (x) ->
    isObject(x) and 'function' is typeof x.then

module.exports =

###################################################################################
# interface

    # callback style decorator
    #
    # like _inject but can be called with 2 or three arguments and
    # does some basic input checking
    #
    # example:
    #
    # inject [container1, container2], ['id1', 'id2'], (arg1, arg2) ->
    #
    # inject [container1, container2], (id1, id2) ->

    inject: (deps) ->
        checkDeps deps, 'arrayify', 'parseFunctionArguments', '_inject'
        ->
            len = arguments.length
            unless (len is 2) or (len is 3)
                throw new Error "2 or 3 arguments required but #{len} were given"

            containers = deps.arrayify arguments[0]

            if containers.length is 0
                throw new Error 'at least 1 container is required'

            cb = if len is 2 then arguments[1] else arguments[2]

            unless 'function' is typeof cb
                throw new Error 'cb must be a function'

            dependencyIds = if len is 2
                deps.parseFunctionArguments cb
            else
                arguments[1]

            deps._inject containers, dependencyIds, cb

    # this is the place where it goes from promise land to callback land

    _inject: (deps) ->
        checkDeps deps, 'emitRejection', 'getOrCreateManyInstances'
        (containers, ids, cb) ->
            onResolve = (instances) ->
                process.nextTick ->
                    cb.apply null, instances
            onReject = (rejection) ->
                deps.emitRejection rejection

            promise = deps.getOrCreateManyInstances containers, ids
            promise.done onResolve, onReject

###################################################################################
# container side effecting functions

    getOrCreateManyInstances: (deps) ->
        checkDeps deps, 'getOrCreateInstance'
        (containers, ids) ->
            Promise.all(ids).map (id) ->
                deps.getOrCreateInstance containers, id

    # mostly concerned with debugging and error handling
    # delegates all other stuff to functions

    getOrCreateInstance: (deps) ->
        checkDeps deps,
            'findInstance'
            'emitInstanceFound'
            'isCyclic'
            'cycleRejection'
            'findContainerThatContainsFactory'
            'missingFactoryRejection'
            'getFactory'
            'factoryNotFunctionRejection'
            'startingWith'
            'getUnderConstruction'
            'addUnderConstruction'
            'removeUnderConstruction'
            'createInstance'
        (containers, id) ->
            instance = deps.findInstance containers, id

            if instance?
                deps.emitInstanceFound containers[0], id, instance
                return Promise.resolve instance

            if deps.isCyclic id
                return deps.cycleRejection containers[0], id

            container = deps.findContainerThatContainsFactory containers, id

            unless container?
                return deps.missingFactoryRejection containers[0], id

            # if the instance is already being constructed elsewhere
            # wait for that instead of starting a second construction
            # a factory must only be called exactly once per container

            underConstruction = deps.getUnderConstruction container, id

            if underConstruction?
                return underConstruction

            factory = deps.getFactory container, id

            unless 'function' is typeof factory
                return deps.factoryNotFunctionRejection container, id, factory

            remainingContainers = deps.startingWith containers, container

            instance = deps.createInstance container, id, remainingContainers

            deps.addUnderConstruction container, id, instance

            instance.then (value) ->
                # instance is fully constructed
                deps.removeUnderConstruction container, id
                value

    # side effects `container` by 
    # returns a promise that is resolved with the instance
    # `containers` is a list of containers that will be used
    # to look up the dependencies of the factory in addition to container.
    # after `container` has been side effected.

    createInstance: (deps) ->
        checkDeps deps,
            'getDependencies'
            'getOrCreateManyInstances'
            'callFactory'
            'setInstance'
            'addToId'
            'cacheDependencies'
        (container, id, containers) ->
            dependencyIds = deps.getDependencies container, id

            dependencyIds = dependencyIds.map (x) ->
                deps.addToId id, x

            dependencyInstances = deps.getOrCreateManyInstances containers, dependencyIds

            instance = deps.callFactory container, id, dependencyInstances

            instanceSet = deps.setInstance container, id, instance
            dependenciesCached = deps.cacheDependencies container, id, dependencyInstances

            Promise.all([instanceSet, dependenciesCached]).then ->
                instance

    # calls `factory` with `dependencies`.
    # returns a promise.

    callFactory: (deps) ->
        checkDeps deps,
            'getFactory'
            'missingFactoryRejection'
            'exceptionRejection'
            'emitInstanceCreated'
            'emitPromiseCreated'
            'emitPromiseResolved'
            'rejectionRejection'
        (container, id, dependencyInstances) ->
            Promise.resolve(dependencyInstances).then (dependencyInstances) ->
                factory = deps.getFactory container, id

                unless factory?
                    return deps.missingFactoryRejection container, id

                try
                    instanceOrPromise = factory.apply null, dependencyInstances
                catch err
                    return deps.exceptionRejection container, id, err

                unless isThenable instanceOrPromise
                    # instanceOrPromise is not a promise but an instance
                    deps.emitInstanceCreated container, id, instanceOrPromise
                    return Promise.resolve instanceOrPromise

                # instanceOrPromise is a promise

                deps.emitPromiseCreated container, id, instanceOrPromise

                return instanceOrPromise.then(
                    (value) ->
                        deps.emitPromiseResolved container, id, value
                        return value
                    (rejection) ->
                        deps.rejectionRejection container, id, rejection
                )

###################################################################################
# path

    getKey: ->
        (id) ->
            if Array.isArray id then id[0] else id

    getKeys: (deps)->
        checkDeps deps, 'arrayify'
        (id) ->
            deps.arrayify id

    idToString: (deps) ->
        checkDeps deps, 'getKeys'
        (id) ->
            deps.getKeys(id).join ' <- '

    addToId: (deps) ->
        checkDeps deps, 'arrayify'
        (id, key) ->
            [key].concat deps.arrayify id

    isCyclic: (deps) ->
        checkDeps deps, 'arrayOfStringsHasDuplicates', 'getKeys'
        (id) ->
            deps.arrayOfStringsHasDuplicates deps.getKeys id

###################################################################################
# container getters

    getEmitter: ->
        (container) ->
            container.emitter ?= new events.EventEmitter
            container.emitter

    getInstance: (deps) ->
        checkDeps deps, 'getKey'
        (container, id) ->
            container?.instances?[deps.getKey id]

    getFactory: (deps) ->
        checkDeps deps, 'getKey'
        (container, id) ->
            container?.factories?[deps.getKey id]

    getDependencies: (deps) ->
        checkDeps deps, 'getKey', 'getFactory', 'parseFunctionArguments'
        (container, id) ->
            key = deps.getKey id
            if container.dependencies?[key]?
                return container.dependencies[key]

            factory = deps.getFactory container, id

            unless factory?
                return null

            deps.parseFunctionArguments factory

###################################################################################
# container find functions

    findContainerThatContainsFactory: (deps) ->
        checkDeps deps, 'find', 'getFactory'
        (containers, id) ->
            deps.find containers, (x) ->
                deps.getFactory(x, id)?

    findContainerThatContainsInstance: (deps) ->
        checkDeps deps, 'find', 'getInstance'
        (containers, id) ->
            deps.find containers, (x) ->
                deps.getInstance(x, id)?

    findInstance: (deps) ->
        checkDeps deps, 'getInstance', 'findContainerThatContainsInstance'
        (containers, id) ->
            container = deps.findContainerThatContainsInstance containers, id
            deps.getInstance container, id

###################################################################################
# under construction

    getUnderConstruction: (deps) ->
        checkDeps deps, 'getKey'
        (container, id) ->
            container.underConstruction?[deps.getKey id]

    addUnderConstruction: (deps) ->
        checkDeps deps, 'getKey'
        (container, id, promise) ->
            container.underConstruction ?= {}
            container.underConstruction[deps.getKey id] = promise

    removeUnderConstruction: (deps) ->
        checkDeps deps, 'getKey'
        (container, id) ->
            container.underConstruction ?= {}
            promise = container.underConstruction[deps.getKey id]
            delete container.underConstruction[deps.getKey id]
            promise

###################################################################################
# container setters

    # returns promise
    setInstance: (deps) ->
        checkDeps deps, 'getKey'
        (container, id, instance) ->
            Promise.resolve(instance).then (value) ->
                container.instances ?= {}
                container.instances[deps.getKey id] = value
                return value

    # returns promise
    cacheDependencies: (deps) ->
        checkDeps deps, 'getKey'
        (container, id, dependencies) ->
            Promise.resolve(dependencies).then (value) ->
                container.dependencyCache ?= {}
                container.dependencyCache[deps.getKey id] = value
                return value

###################################################################################
# emit

    # synchronous
    emit: (deps) ->
        checkDeps deps, 'getEmitter', 'event'
        (container) ->
            deps.getEmitter(container).emit deps.event, Array.prototype.slice.call(arguments, 1)

###################################################################################
# error

    cycleRejection: (deps) ->
        checkDeps deps, 'idToString'
        (container, id) ->
            error = new Error "circular dependency #{deps.idToString id}"
            error.name = 'cycle'
            error.id = id
            error.container = container
            return Promise.reject error

    missingFactoryRejection: (deps) ->
        checkDeps deps, 'getKey', 'idToString'
        (container, id) ->
            error = new Error "missing factory '#{deps.getKey id}' (#{deps.idToString id})"
            error.name = 'missingFactory'
            error.id = id
            error.container = container
            return Promise.reject error

    exceptionRejection: (deps) ->
        checkDeps deps, 'getKey'
        (container, id, exception) ->
            error = new Error "exception in factory '#{deps.getKey id}': #{exception}"
            error.name = 'exceptionRejection'
            error.exception = exception
            error.id = id
            error.container = container
            return Promise.reject error

    rejectionRejection: (deps) ->
        checkDeps deps, 'getKey'
        (container, id, rejection) ->
            error = new Error "promise returned from factory '#{deps.getKey id}' was rejected with: #{rejection}"
            error.name = 'rejectionRejection'
            error.rejection = rejection
            error.id = id
            error.container = container
            return Promise.reject error

    factoryNotFunctionRejection: (deps) ->
        checkDeps deps, 'getKey'
        (container, id, factory) ->
            error = "factory '#{deps.getKey id}' is not a function: #{factory}"
            error.name = 'factoryNotFunction'
            error.factory = factory
            error.id = id
            error.container = container
            return Promise.reject error

    emitRejection: (deps) ->
        checkDeps deps, 'emitError'
        (rejection) ->
            deps.emitError rejection.container, rejection
