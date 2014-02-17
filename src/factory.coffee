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

module.exports.inject = (
    arrayify
    parseFunctionArguments
    _inject
) ->
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

# where it goes from promise land to callback land...

module.exports._inject = (
    emitError
    getOrCreateManyInstances
) ->
    (containers, ids, cb) ->
        onResolve = (instances) ->
            process.nextTick ->
                cb.apply null, instances
        onReject = (rejection) ->
            console.log 'REJECTION', rejection
            emitError rejection

        promise = getOrCreateManyInstances containers, ids
        promise.done onResolve, onReject

###################################################################################
# container side effecting functions

module.exports.getOrCreateManyInstances = (
    getOrCreateInstance
    Promise
) ->
    (containers, ids) ->
        Promise.all(ids).map (id) ->
            getOrCreateInstance containers, id

# mostly concerned with debugging and error handling
# delegates all other stuff to functions

module.exports.getOrCreateInstance = (
    findInstance
    emit
    Promise
    getFactory
    isCyclic
    cycleRejection
    findContainerThatContainsFactory
    missingFactoryRejection
    getUnderConstruction
    factoryNotFunctionRejection
    startingWith
    createInstance
    addUnderConstruction
    removeUnderConstruction
) ->
    (containers, id) ->
        instance = findInstance containers, id

        if instance?
            emit
                event: 'instanceFound'
                id: id
                value: instance
                container: containers[0]
            return Promise.resolve instance

        if isCyclic id
            return cycleRejection containers[0], id

        container = findContainerThatContainsFactory containers, id

        unless container?
            return missingFactoryRejection containers[0], id

        # if the instance is already being constructed elsewhere
        # wait for that instead of starting a second construction
        # a factory must only be called exactly once per container

        underConstruction = getUnderConstruction container, id

        if underConstruction?
            return underConstruction

        factory = getFactory container, id

        unless 'function' is typeof factory
            return factoryNotFunctionRejection container, id, factory

        remainingContainers = startingWith containers, container

        instance = createInstance container, id, remainingContainers

        addUnderConstruction container, id, instance

        instance.then (value) ->
            # instance is fully constructed
            removeUnderConstruction container, id
            value

# side effects `container` by setting an instance
# returns a promise that is resolved with the instance
# `containers` is a list of containers that will be used
# to look up the dependencies of the factory in addition to container.
# after `container` has been side effected.

module.exports.createInstance = (
    Promise
    getDependencies
    getOrCreateManyInstances
    callFactory
    setInstance
    addToId
    cacheDependencies
) ->
    (container, id, containers) ->
        dependencyIds = getDependencies container, id

        dependencyIds = dependencyIds.map (x) ->
            addToId id, x

        dependencyInstances = getOrCreateManyInstances containers, dependencyIds

        instance = callFactory container, id, dependencyInstances

        instanceSet = setInstance container, id, instance
        dependenciesCached = cacheDependencies container, id, dependencyInstances

        Promise.all([instanceSet, dependenciesCached]).then ->
            instance

# calls `factory` with `dependencies`.
# returns a promise.

module.exports.callFactory = (
    Promise
    isThenable
    getFactory
    missingFactoryRejection
    exceptionRejection
    emit
    rejectionRejection
) ->
    (container, id, dependencyInstances) ->
        Promise.resolve(dependencyInstances).then (dependencyInstances) ->
            factory = getFactory container, id

            unless factory?
                return missingFactoryRejection container, id

            try
                instanceOrPromise = factory.apply null, dependencyInstances
            catch err
                return exceptionRejection container, id, err

            unless isThenable instanceOrPromise
                # instanceOrPromise is not a promise but an instance
                emit
                    event: 'instanceCreated',
                    id: id
                    value: instanceOrPromise
                    container: container
                return Promise.resolve instanceOrPromise

            # instanceOrPromise is a promise

            emit
                event: 'promiseCreated'
                id: id
                value: instanceOrPromise
                container: container

            return instanceOrPromise.then(
                (value) ->
                    emit
                        event: 'promiseResolved'
                        id: id
                        value: value
                        container: container
                    return value
                (rejection) ->
                    rejectionRejection container, id, rejection
            )

###################################################################################
# path manipulation

module.exports.getKey = ->
    (id) ->
        if Array.isArray id then id[0] else id

module.exports.getKeys = (
    arrayify
) ->
    (id) ->
        arrayify id

module.exports.idToString = (
    getKeys
) ->
    (id) ->
        getKeys(id).join ' <- '

module.exports.addToId = (
    arrayify
) ->
    (id, key) ->
        [key].concat arrayify id

module.exports.isCyclic = (
    arrayOfStringsHasDuplicates
    getKeys
) ->
    (id) ->
        arrayOfStringsHasDuplicates getKeys id

###################################################################################
# container getters

module.exports.getEmitter = (
    EventEmitter
) ->
    (container) ->
        container.emitter ?= new EventEmitter()
        container.emitter

module.exports.getInstance = (
    getKey
) ->
    (container, id) ->
        container?.instances?[getKey(id)]

module.exports.getFactory = (
    getKey
) ->
    (container, id) ->
        container?.factories?[getKey(id)]

module.exports.getDependencies = (
    getKey
    getFactory
    parseFunctionArguments
) ->
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

module.exports.findContainerThatContainsFactory = (
    find
    getFactory
) ->
    (containers, id) ->
        find containers, (x) ->
            getFactory(x, id)?

module.exports.findContainerThatContainsInstance = (
    find
    getInstance

) ->
    (containers, id) ->
        find containers, (x) ->
            getInstance(x, id)?

module.exports.findInstance = (
    getInstance
    findContainerThatContainsInstance
) ->
    (containers, id) ->
        container = findContainerThatContainsInstance containers, id
        getInstance container, id

###################################################################################
# under construction

module.exports.getUnderConstruction = (
    getKey
) ->
    (container, id) ->
        container.underConstruction?[getKey(id)]

module.exports.addUnderConstruction = (
    getKey
) ->
    (container, id, promise) ->
        container.underConstruction ?= {}
        container.underConstruction[getKey(id)] = promise

module.exports.removeUnderConstruction = (
    getKey
) ->
    (container, id) ->
        container.underConstruction ?= {}
        promise = container.underConstruction[getKey(id)]
        delete container.underConstruction[getKey(id)]
        promise

###################################################################################
# container setters

# returns promise
module.exports.setInstance = (
    getKey
    Promise
) ->
    (container, id, instance) ->
        Promise.resolve(instance).then (value) ->
            container.instances ?= {}
            container.instances[getKey(id)] = value
            return value

# returns promise
module.exports.cacheDependencies = (
    getKey
    Promise
) ->
    (container, id, dependencies) ->
        Promise.resolve(dependencies).then (value) ->
            container.dependencyCache ?= {}
            container.dependencyCache[getKey(id)] = value
            return value

###################################################################################
# emit

module.exports.emit = (
    getEmitter
) ->
    (event) ->
        emitter = getEmitter event.container
        emitter.emit 'any', event
        emitter.emit event.event, event

module.exports.emitError = (
    getEmitter
) ->
    (error) ->
        emitter = getEmitter error.container
        emitter.emit 'error', error

###################################################################################
# error

module.exports.cycleRejection = (
    Promise
    idToString
) ->
    (container, id) ->
        Promise.reject
            error: "circular dependency #{idToString(id)}"
            type: 'cycle'
            id: id
            container: container

module.exports.missingFactoryRejection = (
    Promise
    getKey
    idToString
) ->
    (container, id) ->
        Promise.reject
            error: "missing factory '#{getKey(id)}' (#{idToString(id)})"
            type: 'missingFactory'
            id: id
            container: container

module.exports.exceptionRejection = (
    Promise
    getKey
) ->
    (container, id, exception) ->
        Promise.reject
            error: "exception in factory '#{getKey(id)}': #{exception}"
            type: 'exceptionRejection'
            id: id
            exception: exception
            container: container

module.exports.rejectionRejection = (
    Promise
    getKey
) ->
    (container, id, rejection) ->
        Promise.reject
            error: "promise returned from factory '#{getKey(id)}' was rejected with reason: #{rejection}"
            type: 'rejectionRejection'
            id: id
            rejection: rejection
            container: container

module.exports.factoryNotFunctionRejection = (
    Promise
    getKey
) ->
    (container, id, factory) ->
        Promise.reject
            error: "factory '#{getKey(id)}' is not a function: #{factory}"
            type: 'factoryNotFunction'
            id: id
            factory: factory
            container: container
