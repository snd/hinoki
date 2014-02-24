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
    getIdsToInject
    addToId
    getOrCreateManyInstances
    findContainerThatCanResolveInstance
    isCyclic
    isUndefined
    cycleRejection
    findContainerThatCanResolveFactory
    unresolvableFactoryRejection
    getUnderConstruction
    factoryNotFunctionRejection
    startingWith
    createInstance
    isThenable
) ->
    (containers, id) ->
        instanceResult = findContainerThatCanResolveInstance containers, id

        if instanceResult?
            instanceResult.container.emit instanceResult.container,
                event: 'instanceFound'
                id: id
                instance: instanceResult.instance
                resolver: instanceResult.resolver
                container: instanceResult.container
            return Promise.resolve instanceResult.instance

        # no instance available. we need a factory.
        # let's check for cycles first.
        # we can't use a factory if the id contains a cycle.

        if isCyclic id
            return cycleRejection
                container: containers[0]
                id: id

        # no cycle - yeah!
        # lets find the container that can give us a factory

        factoryResult = findContainerThatCanResolveFactory containers, id

        unless factoryResult?
            # we are out of luck: the factory could not be found
            return unresolvableFactoryRejection
                container: containers[0]
                id: id

        {factory, resolver, container} = factoryResult

        unless 'function' is typeof factory
            # we are out of luck: the resolver didnt return a function
            return factoryNotFunctionRejection
                container: container
                id: id
                factory: factory
                resolver: resolver

        # we've got a factory

        container.emit container,
            event: 'factoryFound'
            id: id
            factory: factory
            resolver: resolver
            container: container

        # if the instance is already being constructed elsewhere
        # wait for that instead of starting a second construction
        # a factory must only be called exactly once per container

        underConstruction = container.getUnderConstruction container, id

        if underConstruction?
            container.emit container,
                event: 'instanceUnderConstruction'
                id: id
                value: underConstruction
                container: container
            return underConstruction

        # there is no instance under construction. lets make one

        # lets resolve the dependencies of the factory

        remainingContainers = startingWith containers, container

        dependencyIds = getIdsToInject factory

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
                container.emit container,
                    event: 'instanceCreated',
                    id: id
                    instance: instanceOrPromise
                    factory: factory
                    container: container
                return Promise.resolve instanceOrPromise

            # instanceOrPromise is a promise

            container.emit container,
                event: 'promiseCreated'
                id: id
                promise: instanceOrPromise
                container: container
                factory: factory

            return instanceOrPromise.then(
                (value) ->
                    container.emit container,
                        event: 'promiseResolved'
                        id: id
                        value: value
                        container: container
                        factory: factory
                    return value
                (rejection) ->
                    rejectionRejection
                        container: container
                        id: id
                        rejection: rejection
            )

        container.setUnderConstruction container, id, instancePromise

        instancePromise.then (value) ->
            if isUndefined value
                return factoryReturnedUndefinedRejection
                    container: container
                    id: id
                    factory: factory
            # instance is fully constructed
            container.setInstance container, id, value
            container.unsetUnderConstruction container, id
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
    getKey
) ->
    (container, id) ->
        some container.factoryResolvers, (resolver) ->
            factory = resolver container, getKey id
            return unless factory?
            {
                resolver: resolver
                factory: factory
            }

# returns either null or {resolver: , instance: }

module.exports.findResolverThatCanResolveInstance = (
    some
    getKey
) ->
    (container, id) ->
        some container.instanceResolvers, (resolver) ->
            instance = resolver container, getKey id
            return unless instance?
            {
                resolver: resolver
                instance: instance
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

module.exports.findContainerThatCanResolveInstance = (
    some
    findResolverThatCanResolveInstance
) ->
    (containers, id) ->
        some containers, (container) ->
            result = findResolverThatCanResolveInstance container, id
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

module.exports.emitError = ->
    (error) ->
        unless error.container?
            # bug in hinoki itself!
            # TODO throw a more helpful error message
            throw error
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
    (container, event) ->
        container.emitter.emit event.event, event
        container.emitter.emit 'any', event

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
