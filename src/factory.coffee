events = require 'events'

Q = require 'q'

module.exports =

###################################################################################
# path

    getKey: ->
        (id) ->
            if Array.isArray id then id[0] else id

    getKeys: ({
        arrayify
    }) ->
        (id) ->
            arrayify id

    idToString: ({
        getKeys
    }) ->
        (id) ->
            getKeys(id).join ' <- '

    addToId: ({
        arrayify
    }) ->
        (id, key) ->
            [key].concat arrayify id

    isCyclic: ({
        getKeys
        arrayOfStringsHasDuplicate
    }) ->
        (id) ->
            arrayOfStringsHasDuplicate getKeys id

###################################################################################
# container getters

    getEmitter: ->
        (container) ->
            container.emitter ?= new events.EventEmitter
            container.emitter

    getInstance: ({
        getKey
    }) ->
        (container, id) ->
            container?.instances?[getKey id]

    getFactory: ({
        getKey
    }) ->
        (container, id) ->
            container?.factories?[getKey id]

    getDependencies: ({
        parseFunctionArguments
        getKey
        getFactory
    }) ->
        (container, id) ->
            key = getKey id
            if container.dependencies?[key]?
                return container.dependencies[key]

            factory = getFactory container, id

            unless factory?
                return null

            parseFunctionArguments factory

###################################################################################
# container find functions

    findContainerThatContainsFactory: ({
        find
        getFactory
    }) ->
        (containers, id) ->
            find containers, (x) -> getFactory(x, id)?

    findInstance: ({
        find
        getInstance
    }) ->
        (containers, id) ->
            container = find containers, (x) -> getInstance(x, id)?
            getInstance container, id

###################################################################################
# container setters

    # returns promise
    setInstance: ({
        getKey
    }) ->
        (container, id, instance) ->
            Q(instance).then (value) ->
                container.instances ?= {}
                container.instances[getKey id] = value
                return value

    # returns promise
    setDependencies: ({
        getKey
    }) ->
        (container, id, dependencies) ->
            Q(dependencies).then (value) ->
                # TODO reject if no container
                container.dependencies ?= {}
                container.dependencies[getKey id] = value
                return value

###################################################################################
# emit

    # synchronous
    emit: ({
        getEmitter
        event
    }) ->
        (container) ->
            getEmitter(container).emit event Array.prototype.slice.call(arguments, 1)

###################################################################################
# error

    cycleRejection: ({
        idToString
    }) ->
        (container, id) ->
            error = new Error "circular dependency #{idToString id}"
            error.name = 'cycle'
            error.id = id
            error.container = container
            return Q.reject error

    missingFactoryRejection: ({
        idToString
        getKey
    }) ->
        (container, id) ->
            error = new Error "missing factory '#{getKey id}' (#{idToString id})"
            error.name = 'missingFactory'
            error.id = id
            error.container = container
            return Q.reject error

    exceptionRejection: ({
        getKey
    }) ->
        (container, id, exception) ->
            error = new Error "exception in factory '#{getKey id}': #{err}"
            error.name = 'exceptionRejection'
            error.exception = exception
            error.id = id
            error.container = container
            return Q.reject error

    rejectionRejection: ({
        getKey
    }) ->
        (container, id, rejection) ->
            error = new Error "promise returned from factory '#{getKey id}' was rejected with: #{rejection}"
            error.name = 'rejectionRejection'
            error.rejection = rejection
            error.id = id
            error.container = container
            return Q.reject error

    factoryNotFunctionRejection: ({
        getKey
    }) ->
        (container, id, factory) ->
            error = "factory '#{getKey id}' is not a function: #{factory}"
            error.name = 'factoryNotFunction'
            error.factory = factory
            error.id = id
            error.container = container
            return Q.reject error

    emitRejection: ({
        emit
    }) ->
        (rejection) ->
            emit rejection.container, 'error', rejection

###################################################################################
# container side effecting functions

    # calls `factory` with `dependencies`.
    # returns a promise.

    callFactory: ({
        getFactory,
        emitInstanceCreated,
        emitPromiseCreated,
        emitPromiseResolved,
        emitPromiseRejected,
        missingFactoryRejection,
        exceptionRejection,
        rejectionRejection
    }) ->
        (container, id, dependencyInstances) ->
            Q(dependencyInstances).then (dependencyInstances) ->
                factory = getFactory container, id

                unless factory?
                    return missingFactoryRejection container, id

                try
                    instanceOrPromise = factory.apply null, dependencyInstances
                catch err
                    return exceptionRejection container, id, err

                # not a promise
                unless Q.isPromiseAlike instanceOrPromise
                    emitInstanceCreated container, id, instanceOrPromise
                    return Q instanceOrPromise

                emitPromiseCreated container, id, instanceOrPromise

                onResolve = (value) ->
                    emitPromiseResolved container, id, value
                    return value

                onReject = (rejection) ->
                    rejectionRejection container, id, rejection

                return instanceOrPromise.then onResolve, onReject

    # side effects `container` by 
    # returns a promise that is resolved with the instance
    # `containers` is a list of containers that will be used
    # to look up the dependencies of the factory in addition to container.
    # after `container` has been side effected.

    createInstance: ({
        getDependencies
        getInstances
        callFactory
    }) ->
        (container, id, containers) ->
            dependencyIds = getDependencies container, id

            dependencyIds = dependencyIds.map (x) -> addToId id, x

            dependencyInstances = getInstances containers, dependencyIds

            factory = getFactory container, id

            instance = callFactory container, factory, dependencyInstances

            instanceSet = setInstance container, id, instance
            dependenciesSet = setDependencies container, id, dependencyInstances

            Q.all([instanceSet, dependenciesSet]).then ->
                instance

    # mostly concerned with debugging and error handling
    # delegates all other stuff to functions

    getOrCreateInstance: ({
        startingWith
        getInstance
        findInstance
        findContainerThatContainsFactory
        createInstance
        emitInstanceFound
        factoryNotFoundRejection
        factoryNotFunctionRejection
        cycleRejection
        getFactory
        hasCycle
    }) ->
        (containers, id) ->
            instance = findInstance containers, id

            if instance?
                emitInstanceFound containers[0], id, instance
                return Q.resolve instance

            if hasCycle id
                return cycleRejection containers[0], id

            container = findContainerThatContainsFactory containers, id

            unless container?
                return factoryNotFoundRejection containers[0], id

            factory = getFactory container, id

            unless 'function' is typeof factory
                return factoryNotFunctionRejection container, id, factory

            remainingContainers = startingWith containers, container

            instance = createInstance container, remainingContainers, id

    getOrCreateManyInstances: ({
        getOrCreateInstance
    }) ->
        (containers, ids) ->
            Q.all ids.map (id) ->
                getOrCreateInstance containers, id

###################################################################################
# interface

    # this is the place where it goes from promise land to callback land

    _inject: ({
        getOrCreateManyInstances
        emitRejection
    }) ->
        (containers, ids, cb) ->
            onResolve = (instances) ->
                process.nextTick ->
                    cb.apply null, instances
            onReject = (rejection) ->
                process.nextTick ->
                    emitRejection rejection

            promise = getOrCreateManyInstances containers, ids
            promise.done onResolve, onReject

    # callback style decorator
    #
    # example:
    #
    # varargsInject [container1, container2], ['id1', 'id2'], (arg1, arg2) ->
    #
    # varargsInject [container1, container2], (id1, id2) ->

    inject: ({
        arrayify,
        parseFunctionArguments,
        _inject
    }) ->
        ->
            len = arguments.length
            unless (len is 2) or (len is 3)
                throw new Error "2 or 3 arguments required but #{len} were given"

            containers = arrayify arguments[0]

            if containers.length is 0
                throw new Error 'at least 1 container is required'

            cb = if len is 2 then arguments[1] else arguments[2]

            unless 'function' is typeof cb
                throw new Error 'cb must be a function'

            dependencyIds = if len is 2
                parseFunctionArguments cb
            else
                arguments[1]

            _inject containers, dependencyIds, cb
