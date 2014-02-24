###################################################################################
# functions that inject into a factory function

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
    getIdsToInject
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

        dependencyIds = if len is 2 then getIdsToInject cb else arguments[1]

        _inject containers, dependencyIds, cb

# where it goes from promise land to callback land...

# TODO rename
module.exports._inject = (
    emitError
    getOrCreateManyInstances
) ->
    (containers, ids, cb) ->
        onResolve = (instances) ->
            process.nextTick ->
                cb.apply null, instances
        onReject = (rejection) ->
            emitError rejection

        promise = getOrCreateManyInstances containers, ids
        promise.done onResolve, onReject

###################################################################################
# functions that return promises

module.exports.getOrCreateManyInstances = (
    getOrCreateInstance
    Promise
) ->
    (containers, ids) ->
        Promise.all(ids).map (id) ->
            getOrCreateInstance containers, id

module.exports.getOrCreateInstance = (
    Promise
    emit
    findFirstContainerThatCanResolveInstance
    isCyclic
    cycleRejection
    findFirstContainerThatCanResolveFactory
    unresolvableFactoryRejection
    getUnderConstruction
    factoryNotFunctionRejection
    startingWith
    createInstance
) ->
    (containers, id) ->
        instanceResult = findFirstContainerThatCanResolveInstance containers, id

        if instanceResult?
            emit
                event: 'instanceResolved'
                id: id
                instance: instanceResult.instance
                resolver: instanceResult.resolver
                container: instanceResult.container
            return Promise.resolve instanceResult.instance

        # no instance available. we need a factory.
        # let's check for cycles first.
        # we can't use a factory if the id contains a cycle.

        if isCyclic id
            return cycleRejection containers[0], id

        # no cycle - yeah!
        # lets find the container that can give us a factory

        container = findFirstContainerThatCanResolveId containers, id

        unless container?
            return unresolvableFactoryRejection containers[0], id

        # if the instance is already being constructed elsewhere
        # wait for that instead of starting a second construction
        # a factory must only be called exactly once per container

        underConstruction = container.getUnderConstruction container, id

        if underConstruction?
            emit
                event: 'instanceUnderConstruction'
                id: id
                value: underConstruction
                container: container
            return underConstruction

        # there is no instance under construction. lets make one

        factoryResult = findFirstContainerThatCanResolveFactory containers, id

        unless factoryResult?
            # we are out of luck: the factory could not be found
            return unresolvableFactoryRejection
                container: container
                id: id

        unless 'function' is typeof factoryResult.factory
            # we are out of luck: the resolver didnt return a function
            return factoryNotFunctionRejection
                    container: factoryResult.container
                    id: id
                    factory: factory
                    resolver: factoryResult.resolver

        container = factoryResult.container
        factory = factoryResult.factory

        # we've got a factory

        emit
            event: 'factoryFound'
            id: id
            value: factory
            resolver: factoryResult.resolver
            container: container

        # lets resolve the dependencies of the factory

        remainingContainers = startingWith containers, container

        dependencyIds = getIdsToInject factoryResult.factory

        dependencyIds = dependencyIds.map (x) ->
            addToId id, x

        dependencyPromises = getOrCreateManyInstances remainingContainers, dependencyIds

        instancePromise = Promise.resolve(dependencyPromises).then (dependencyInstances) ->

            # the dependencies are ready
            # and we are finally ready to call the factory

            try
                instanceOrPromise = factory.apply null, dependencyInstances
            catch err
                return exceptionRejection
                    exception: err

            unless isThenable instanceOrPromise
                # instanceOrPromise is not a promise but an instance
                emit
                    event: 'instanceCreated',
                    instance: instanceOrPromise
                return Promise.resolve instanceOrPromise

            # instanceOrPromise is a promise

            emit
                event: 'promiseCreated'
                id: id
                promise: instanceOrPromise
                container: container
                factory: factory

            return instanceOrPromise.then(
                (value) ->
                    emit
                        event: 'promiseResolved'
                        id: id
                        value: value
                        container: container
                        factory: factory
                    return value
                (rejection) ->
                    rejectionRejection container, id, rejection
            )

        container.addUnderConstruction container, id, instancePromise

        instancePromise.then (value) ->
            if isUndefined value
                return factoryReturnedUndefinedRejection
                    container: container
                    id: id
                    factory: factory
            # instance is fully constructed
            container.setInstance container, id, instance
            container.removeUnderConstruction container, id
            value

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
# functions that resolve factories and instances

# returns either null or {resolver: , instance: }

module.exports.findResolverThatCanResolveFactory = (
    some
) ->
    (container, id) ->
        some container.factoryResolvers, (resolver) ->
            factory = resolver container, id
            return unless factory?
            {
                resolver: resolver
                factory: factory
            }

# returns either null or {resolver: , instance: }

module.exports.findResolverThatCanResolveInstance = (
    some
) ->
    (container, id) ->
        some container.instanceResolvers, (resolver) ->
            instance = resolver container, id
            return unless instance?
            {
                resolver: resolver
                factory: instance
            }

# returns either null or {container: , resolver: , factory: }

module.exports.findContainerThatCanResolveFactory = (
    some
    findResolverThatCanResolveFactory
) ->
    (containers, id) ->
        some containers, (container) ->
            result = findResolverThatCanResolveFactory container, id
            return unless result?
            result.container = container
            result

# returns either null or {container: , resolver: , instance: }

module.exports.find = (
    some
    findResolverThatCanResolveInstance
) ->
    (containers, id) ->
        some containers, (container) ->
            result = findContainerThatCanResolveInstance container, id
            return unless result?
            result.container = container
            result

###################################################################################
# util

module.exports.getIdsToInject = (
    parseFunctionArguments
) ->
    (factory) ->
        if factory.$inject?
            factory.$inject
        else
            parseFunctionArguments factory

###################################################################################
# emit

module.exports.emit = ->
    (event) ->
        event.container.emit 'any', event
        event.container.emit event.event, event

module.exports.emitError = ->
    (error) ->
        error.container.emit 'error', error

###################################################################################
# error

module.exports.cycleRejection = (
    Promise
    idToString
) ->
    (params) ->
        Promise.reject
            error: "circular dependency #{idToString(params.id)}"
            type: 'cycle'
            id: params.id
            container: params.container

module.exports.unresolvableFactoryRejection = (
    Promise
    getKey
    idToString
) ->
    (params) ->
        Promise.reject
            error: "unresolvable factory '#{getKey(params.id)}' (#{idToString(params.id)})"
            type: 'unresolvableFactory'
            id: params.id
            container: params.container

module.exports.exceptionRejection = (
    Promise
    getKey
) ->
    (params) ->
        Promise.reject
            error: "exception in factory '#{getKey(params.id)}': #{params.exception}"
            type: 'exceptionRejection'
            id: params.id
            exception: params.exception
            container: params.container

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
    (params) ->
        Promise.reject
            error: "factory '#{getKey(params.id)}' is not a function: #{params.factory}"
            type: 'factoryNotFunction'
            id: params.id
            factory: params.factory
            container: params.container

###################################################################################
# sugar for container construction

module.exports.newContainer = (
    defaultInstanceResolver
    defaultFactoryResolver
    defaultEmit
    defaultSetInstance
    defaultSetUnderConstruction
    defaultUnsetUnderConstruction
    defaultGetUnderConstruction
    EventEmitter
) ->
    (factories = {}, instances = {}) ->
        {
            factories: factories
            instances: instances
            factoryResolvers: [defaultFactoryResolver]
            instanceResolvers: [defaultInstanceResolver]
            underConstruction: {}
            setInstance: defaultSetInstance
            setUnderConstruction: defaultSetUnderConstruction
            unsetUnderConstruction: defaultUnsetUnderConstruction
            getUnderConstruction: defaultGetUnderConstruction
            emit: defaultEmit
            emitter: new EventEmitter
        }

###################################################################################
# defaults

module.exports.defaultInstanceResolver = ->
    (container, id) ->
        container.instances?[id]

module.exports.defaultFactoryResolver = (
    parseFunctionArguments
) ->
    (container, id) ->
        factory = container.factories?[id]
        unless factory?
            return

        # add $inject such that parseFunctionArguments is called only once per factory
        unless factory.$inject?
            factory.$inject = parseFunctionArguments factory

        return factory

module.exports.defaultSetInstance = ->
    (container, id, instance) ->
        container.instances[id] = instance

module.exports.defaultEmit = ->
    (container, name, event) ->
        container.emitter.emit name event

module.exports.defaultSetUnderConstruction = ->
    (container, id, underConstruction) ->
        container.underConstruction[id] = underConstruction

module.exports.defaultUnsetUnderConstruction = ->
    (container, id) ->
        value = container.underConstruction[id]
        delete container.underConstruction[id]
        value

module.exports.defaultGetUnderConstruction = ->
    (container, id) ->
        container.underConstruction[id]
