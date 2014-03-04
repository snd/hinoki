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
  getOrCreateManyInstances
) ->
  (containers, ids, cb) ->
    promise = getOrCreateManyInstances containers, ids
    promise
      .then (instances) ->
        process.nextTick ->
          cb.apply null, instances
      .catch (error) ->
        error.event = 'error'
        unless error.container?
          throw new Error "error has no container property. there is probably a bug in hinoki itself. original error: #{error}"
        error.container.emit error.container, error

###################################################################################
# functions that do the heavy lifting

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
  resolveInstanceInContainers
  isCyclic
  isUndefined
  cycleRejection
  resolveFactoryInContainers
  unresolvableFactoryRejection
  startingWith
  createInstance
  getKey
  callFactory
  factoryReturnedUndefinedRejection
) ->
  (containers, id) ->
    # resolveInstanceInContainers has the opportunity
    # to return an error through a rejected promise that
    # is returned by getOrCreateManyInstances unchanged
    instanceResultPromise = resolveInstanceInContainers containers, id

    if instanceResultPromise?
      return instanceResultPromise.then (instanceResult) ->
        instanceResult.container.emit instanceResult.container,
          event: 'instanceResolved'
          id: id
          instance: instanceResult.instance
          resolver: instanceResult.resolver
          container: instanceResult.container
        instanceResult.instance

    # no instance available. we need a factory.
    # let's check for cycles first since
    # we can't use a factory if the id contains a cycle.

    if isCyclic id
      return cycleRejection
        container: containers[0]
        id: id

    # no cycle - yeah!
    # lets find the container that can give us a factory

    # resolveFactoryInContainers has the opportunity
    # to return an error through a rejected promise that
    # is returned by getOrCreateManyInstances unchanged
    factoryResultPromise = resolveFactoryInContainers containers, id

    unless factoryResultPromise?
      # we are out of luck: the factory could not be found
      return unresolvableFactoryRejection
        container: containers[0]
        id: id

    # we've got a factory

    factoryResultPromise.then (factoryResult) ->
      {factory, resolver, container} = factoryResult

      container.emit container,
        event: 'factoryFound'
        id: id
        factory: factory
        resolver: resolver
        container: container

      # if the instance is already being constructed
      # wait for that instead of starting a second construction.
      # a factory must only be called exactly once per container.

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

      key = getKey id

      container.setUnderConstruction container, key, instancePromise

      instancePromise = Promise.resolve(dependencyPromises).then (dependencyInstances) ->

        # the dependencies are ready
        # and we can finally call the factory

        callFactory container, id, factory, dependencyInstances

      instancePromise.then (value) ->
        if isUndefined value
          return factoryReturnedUndefinedRejection
            container: container
            id: id
            factory: factory
        # instance is fully constructed
        container.setInstance container, key, value
        container.unsetUnderConstruction container, key
        value

module.exports.callFactory = (
  Promise
  isThenable
  exceptionRejection
  rejectionRejection

) ->
  (container, id, factory, dependencyInstances) ->
    try
      instanceOrPromise = factory.apply null, dependencyInstances
    catch err
      return exceptionRejection
        exception: err
        id: id
        container: container

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

    return instanceOrPromise
      .then (value) ->
        container.emit container,
          event: 'promiseResolved'
          id: id
          value: value
          container: container
          factory: factory
        return value
      .catch (rejection) ->
        rejectionRejection
          container: container
          id: id
          rejection: rejection

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
# functions that resolve factories

# returns either null or a promise that resolves to {resolver: , factory: }

module.exports.resolveFactoryInContainer = (
  Promise
  factoryNotFunctionRejection
  some
  getKey
) ->
  (container, id) ->
    some container.factoryResolvers, (resolver) ->
      factory = resolver container, getKey id

      # this resolver can't resolve the factory
      unless factory?
        return

      unless 'function' is typeof factory
        # we are out of luck: the resolver didnt return a function
        return factoryNotFunctionRejection
          container: container
          id: id
          factory: factory
          resolver: resolver

      Promise.resolve
        resolver: resolver
        factory: factory

# returns either null or a promise that resolves to {container: , resolver: , factory: }

module.exports.resolveFactoryInContainers = (
  some
  resolveFactoryInContainer
) ->
  (containers, id) ->
    some containers, (container) ->
      promise = resolveFactoryInContainer container, id

      unless promise?
        return

      promise.then (result) ->
        result.container = container
        result

###################################################################################
# functions that resolve instances

# returns either null or a promise that resolves to {resolver: , instance: }

module.exports.resolveInstanceInContainer = (
  Promise
  some
  getKey
) ->
  (container, id) ->
    some container.instanceResolvers, (resolver) ->
      instance = resolver container, getKey id

      unless instance?
        return

      Promise.resolve
        resolver: resolver
        instance: instance

# returns either null or a promise that resolves to {container: , resolver: , instance: }

module.exports.resolveInstanceInContainers = (
  some
  resolveInstanceInContainer
) ->
  (containers, id) ->
    some containers, (container) ->
      promise = resolveInstanceInContainer container, id

      unless promise?
        return

      promise.then (result) ->
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
      type: 'exception'
      id: params.id
      exception: params.exception
      container: params.container

module.exports.rejectionRejection = (
  Promise
  getKey
) ->
  (params) ->
    Promise.reject
      error: "promise returned from factory '#{getKey(params.id)}' was rejected with reason: #{params.rejection}"
      type: 'rejection'
      id: params.id
      rejection: params.rejection
      container: params.container

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

module.exports.factoryReturnedUndefinedRejection = (
  Promise
  getKey
) ->
  (params) ->
    Promise.reject
      error: "factory '#{getKey(params.id)}' returned undefined"
      type: 'factoryReturnedUndefined'
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
    if not factory.$inject? and 'function' is typeof factory
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
