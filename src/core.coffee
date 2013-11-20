# simple, self contained functions

events = require 'events'

Q = require 'q'

module.exports =

    # find an instance in an array of containers

    findInstance: (getInstance) ->
        (containers, id) ->
            container = find containers, (x) -> getInstance(x, id)?
            getInstance container, id

    findContainerThatContainsFactory: (getFactory) ->
        (containers, id) ->
            find containers, (x) -> getFactory(x, id)?

    # container getters
    # -----------------

    getInstance: (getKey) ->
        (container, id) ->
            container?.instances?[getKey id]

    getFactory: (getKey) ->
        (container, id) ->
            container?.factories?[getKey id]

    getEmitter: (container) ->
        container.emitter ?= new events.EventEmitter
        container.emitter

    getDependencies: (parseFunctionArguments, getKey, getFactory) ->
        (container, id) ->
            key = getKey id
            if container.dependencies?[key]?
                return container.dependencies[key]

            factory = getFactory container, id

            unless factory?
                return null

            parseFunctionArguments factory

    # container setters
    # -----------------

    # returns promise
    setInstance: (getKey) ->
        (container, id, instance) ->
            Q(instance).then (value) ->
                container.instances ?= {}
                container.instances[getKey id] = value
                return value

    # returns promise
    setDependencies: (getKey) ->
        (container, id, dependencies) ->
            Q(dependencies).then (value) ->
                # TODO reject if no container
                container.dependencies ?= {}
                container.dependencies[getKey id] = value
                return value

    # container side effecting functions
    # ----------------------------------

    # synchronous
    emit: (getEmitter) ->
        (container, id, event) ->
            # TODO emit should also just use an interface
            getEmitter(arguments[0]).emit Array.prototype.slice.call(arguments, 1)

    # calls `factory` with `dependencies`.
    # returns a promise.

    callFactory: ({
        getFactory,
        emitInstance,
        emitPromise,
        emitResolved,
        emitRejected,
        factoryNotFoundRejection,
        exceptionRejection,
        rejectionRejection
    }) ->
        (container, id, dependencyInstances) ->
            Q(dependencyInstances).then (dependencyInstances) ->
                factory = getFactory container, id

                unless factory?
                    return Q.reject factoryNotFoundRejection container, id

                try
                    instanceOrPromise = factory.apply null, dependencyInstances
                catch err
                    return Q.reject exceptionRejection container, id, err

                unless Q.isPromiseAlike instanceOrPromise
                    emitInstance container, id, instanceOrPromise
                    return Q instanceOrPromise

                emitPromise container, id, instanceOrPromise

                onResolve = (value) ->
                    emitResolved container, id, value
                    Q value

                onReject = (rejection) ->
                    Q.reject rejectionRejection container, id, rejection

                instanceOrPromise.then onResolve, onReject

    # callback style decorator

    overloadedInject: ({
        arrayify,
        parseFunctionArguments,
        inject
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

            inject containers, dependencyIds, cb

    # this is the place where it goes from promise land to callback land

    inject: (getOrCreateManyInstances, emitRejection) ->
        (containers, ids, cb) ->
            onResolve = (instances) ->
                process.nextTick ->
                    cb.apply null, instances
            onReject = (rejection) ->
                process.nextTick ->
                    emitRejection rejection

            promise = getOrCreateManyInstances containers, ids
            promise.done onResolve, onReject

    getOrCreateManyInstances: (getOrCreateInstance) ->
        (containers, ids) ->
            Q.all ids.map (id) ->
                getOrCreateInstance containers, id

    # mostly concerned with debugging and error handling
    # delegates all other stuff to functions

    getOrCreateInstance: (
        getInstance,
        getContainerThatContainsFactory,
        getFactoryDependencies,
        sliceStartingAt,
        getInstancesAsPromise,
        createInstance,
        hasCycle
    ) ->
        (containers, id) ->
            instance = findInstance containers, id

            if instance?
                emit containers[0], 'instanceFound', id, instance
                return Q.resolve instance

            if hasCycle id
                return createRejection 'cycle', containers[0], id

            container = getContainerThatContainsFactory containers, id

            unless container?
                return createRejection 'factoryNotFound', containers[0], id

            factory = getFactory container, id

            unless 'function' is typeof factory
                return createRejection 'factoryNotFunction', container, id

            remainingContainers = getStartingWith containers, container

            instance = createInstance container, remainingContainers, id

    # side effects `container` by 
    # returns a promise that is resolved with the instance
    # `containers` is a list of containers that will be used
    # to look up the dependencies of the factory in addition to container.
    # after `container` has been side effected.

    createInstance: (
        getDependencies,
        getInstances,
        callFactory
    ) ->
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

    # error handling
    # --------------

    createRejection: (getEmitter) ->
        (reason, container, id, err) ->
            {
                reason: reason
                container: getEmitter container
                id: id
                err: err
            }

    emitRejection: (emit, rejectionToError) ->
        (rejection) ->
            emit rejection.container, 'error', rejectionToError rejection

    rejectionToError: (getKeys, idToString) ->
        (rejection) ->
            id = rejection.id
            new Error switch rejection.type
                when 'circle'
                    "circular dependency #{idToString id}"
                when 'factoryNotFound'
                    "missing factory '#{getKey id}' (#{idToString id})"
                when 'exception'
                    "exception in factory '#{getKey id}': #{reason.err}"
                when 'rejection'
                    "promise returned from factory '#{getKey id}' was rejected with: #{reason.err}"
                when 'factoryNotFunction'
                    "factory '#{getKey id}' is not a function: #{reason.factory}"

    # path interface
    # --------------

    idToString: (getKeys) ->
        (id) ->
            getKeys(id).join ' <- '

    getKey: (id) ->
        if Array.isArray id then id[0] else id

    getKeys: (arrayify) ->
        (id) ->
            arrayify id

    isCyclic: (getKeys, arrayOfStringsHasDuplicate) ->
        (id) ->
            arrayOfStringsHasDuplicate getKeys id

    addToId: (arrayify) ->
        (id, key) ->
            [key].concat arrayify id
