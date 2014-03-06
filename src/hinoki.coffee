newHinoki = (Promise) ->

  hinoki = {}

###################################################################################
# get

  hinoki.get = (oneOrManyContainers, oneOrManyIdsOrPaths, debug) ->
      containers = hinoki.arrayify oneOrManyContainers

      if containers.length is 0
        throw new Error 'at least 1 container is required'

      if Array.isArray oneOrManyIdsOrPaths
        hinoki.getMany containers, oneOrManyIdsOrPaths, debug
      else
        hinoki.getOne containers, oneOrManyIdsOrPaths, debug

  hinoki.getMany = (containers, idsOrPaths, debug) ->
      Promise.all(idsOrPaths).map (idOrPath) ->
        hinoki.getOne containers, idOrPath, debug

  hinoki.getOne = (containers, idOrPath, debug) ->
      path = hinoki.castPath idOrPath

      # resolveInstanceInContainers has the opportunity
      # to return an error through a rejected promise that
      # is returned by getOrCreateManyInstances unchanged
      instanceResultPromise = hinoki.resolveInstanceInContainers containers, path

      if instanceResultPromise?
        return instanceResultPromise.then (instanceResult) ->
          debug? {
            event: 'instanceResolved'
            id: path.id()
            path: path.segments()
            instance: instanceResult.instance
            resolver: instanceResult.resolver
            container: instanceResult.container
          }
          instanceResult.instance

      # no instance available. we need a factory.
      # let's check for cycles first since
      # we can't use a factory if the id contains a cycle.

      if path.isCyclic()
        error = new hinoki.CircularDependencyError path, containers[0]
        return Promise.reject error

      # no cycle - yeah!
      # lets find the container that can give us a factory

      # resolveFactoryInContainers has the opportunity
      # to return an error through a rejected promise that
      # is returned by getOrCreateManyInstances unchanged
      factoryResultPromise = hinoki.resolveFactoryInContainers containers, path

      unless factoryResultPromise?
        # we are out of luck: the factory could not be found
        error = new hinoki.UnresolvableFactoryError path, containers[0]
        return Promise.reject error

      # we've got a factory

      factoryResultPromise.then (factoryResult) ->
        {factory, resolver, container} = factoryResult

        debug? {
          event: 'factoryFound'
          id: path.id()
          path: path.segments()
          factory: factory
          resolver: resolver
          container: container
        }

        # if the instance is already being constructed
        # wait for that instead of starting a second construction.
        # a factory must only be called exactly once per container.

        underConstruction = container.getUnderConstruction container, path.id()

        if underConstruction?
          debug? {
            event: 'instanceUnderConstruction'
            id: path.id()
            path: path.segments()
            value: underConstruction
            container: container
          }
          return underConstruction

        # there is no instance under construction. lets make one!

        # lets resolve the dependencies of the factory

        remainingContainers = hinoki.startingWith containers, container

        dependencyIds = hinoki.getIdsToInject factory

        dependencyIds = dependencyIds.map (x) ->
          hinoki.castPath(x).concat path

        dependenciesPromise = hinoki.get remainingContainers, dependencyIds, debug

        container.setUnderConstruction container, path.id(), instancePromise

        instancePromise = dependenciesPromise.then (dependencyInstances) ->

          # the dependencies are ready
          # and we can finally call the factory

          hinoki.callFactory container, path, factory, dependencyInstances, debug

        instancePromise.then (value) ->
          if hinoki.isUndefined value
            error = new hinoki.FactoryReturnedUndefinedError path, container, factory
            return Promise.reject error
          # instance is fully constructed
          container.setInstance container, path.id(), value
          container.unsetUnderConstruction container, path.id()
          value

###################################################################################
# call factory

  hinoki.callFactory = (container, idOrPath, factory, dependencyInstances, debug) ->
    path = hinoki.castPath idOrPath
    try
      instanceOrPromise = factory.apply null, dependencyInstances
    catch exception
      error = new hinoki.ExceptionInFactoryError path, container, exception
      return Promise.reject error

    unless hinoki.isThenable instanceOrPromise
      # instanceOrPromise is not a promise but an instance
      debug? {
        event: 'instanceCreated',
        id: path.id()
        path: path.segments()
        instance: instanceOrPromise
        factory: factory
        container: container
      }
      return Promise.resolve instanceOrPromise

    # instanceOrPromise is a promise

    debug? {
      event: 'promiseCreated'
      id: path.id()
      path: path.segments()
      promise: instanceOrPromise
      container: container
      factory: factory
    }

    instanceOrPromise
      .then (value) ->
        debug? {
          event: 'promiseResolved'
          id: path.id()
          path: path.segments()
          value: value
          container: container
          factory: factory
        }
        return value
      .catch (rejection) ->
        error = new hinoki.PromiseRejectedError path, container, rejection
        Promise.reject error

###################################################################################
# functions that resolve factories

  # returns either null or a promise that resolves to {resolver: , factory: }

  hinoki.resolveFactoryInContainer = (container, idOrPath) ->
    path = hinoki.castPath idOrPath

    hinoki.some container.factoryResolvers, (resolver) ->
      factory = resolver container, path.id()

      # this resolver can't resolve the factory
      unless factory?
        return

      unless 'function' is typeof factory
        # we are out of luck: the resolver didnt return a function
        error = new hinoki.FactoryNotFunctionError path, container, factory
        return Promise.reject error

      Promise.resolve
        resolver: resolver
        factory: factory

  # returns either null or a promise that resolves to {container: , resolver: , factory: }

  hinoki.resolveFactoryInContainers = (containers, idOrPath) ->
    path = hinoki.castPath idOrPath

    hinoki.some containers, (container) ->
      promise = hinoki.resolveFactoryInContainer container, path

      unless promise?
        return

      promise.then (result) ->
        result.container = container
        result

###################################################################################
# functions that resolve instances

  # returns either null or a promise that resolves to {resolver: , instance: }

  hinoki.resolveInstanceInContainer = (container, idOrPath) ->
    path = hinoki.castPath idOrPath

    hinoki.some container.instanceResolvers, (resolver) ->
      instance = resolver container, path.id()

      unless instance?
        return

      Promise.resolve
        resolver: resolver
        instance: instance

  # returns either null or a promise that resolves to {container: , resolver: , instance: }

  hinoki.resolveInstanceInContainers = (containers, idOrPath) ->
    path = hinoki.castPath idOrPath

    hinoki.some containers, (container) ->
      promise = hinoki.resolveInstanceInContainer container, path

      unless promise?
        return

      promise.then (result) ->
        result.container = container
        result

###################################################################################
# sugar for container construction

  hinoki.newContainer = (factories = {}, instances = {}) ->
    factories: factories
    instances: instances
    factoryResolvers: [hinoki.defaultFactoryResolver]
    instanceResolvers: [hinoki.defaultInstanceResolver]
    underConstruction: {}
    setInstance: hinoki.defaultSetInstance
    setUnderConstruction: hinoki.defaultSetUnderConstruction
    unsetUnderConstruction: hinoki.defaultUnsetUnderConstruction
    getUnderConstruction: hinoki.defaultGetUnderConstruction

###################################################################################
# defaults

  hinoki.defaultInstanceResolver = (container, id) ->
    container.instances?[id]

  hinoki.defaultFactoryResolver = (container, id) ->
    factory = container.factories?[id]
    unless factory?
      return

    # add $inject such that parseFunctionArguments is called only once per factory
    if not factory.$inject? and 'function' is typeof factory
      factory.$inject = hinoki.parseFunctionArguments factory

    return factory

  hinoki.defaultSetInstance = (container, id, instance) ->
    container.instances[id] = instance

  hinoki.defaultSetUnderConstruction = (container, id, underConstruction) ->
    container.underConstruction[id] = underConstruction

  hinoki.defaultUnsetUnderConstruction = (container, id) ->
    value = container.underConstruction[id]
    delete container.underConstruction[id]
    value

  hinoki.defaultGetUnderConstruction = (container, id) ->
    container.underConstruction[id]

###################################################################################
# errors

# constructors for errors which are catchable with bluebirds `catch`

  hinoki.CircularDependencyError = (path, container) ->
    this.message = "circular dependency #{path.toString()}"
    this.name = 'CircularDependencyError'
    this.id = path.id()
    this.path = path.segments()
    this.container = container
    if Error.captureStackTrace
      Error.captureStackTrace(this, this.constructor)
  hinoki.CircularDependencyError.prototype = new Error

  hinoki.UnresolvableFactoryError = (path, container) ->
    this.message = "unresolvable factory '#{path.id()}' (#{path.toString()})"
    this.name = 'UnresolvableFactoryError'
    this.id = path.id()
    this.path = path.segments()
    this.container = container
    if Error.captureStackTrace
      Error.captureStackTrace(this, this.constructor)
  hinoki.UnresolvableFactoryError.prototype = new Error

  hinoki.ExceptionInFactoryError = (path, container, exception) ->
    this.message = "exception in factory '#{path.id()}': #{exception}"
    this.name = 'ExceptionInFactoryError'
    this.id = path.id()
    this.path = path.segments()
    this.container = container
    this.exception = exception
    if Error.captureStackTrace
      Error.captureStackTrace(this, this.constructor)
  hinoki.ExceptionInFactoryError.prototype = new Error

  hinoki.PromiseRejectedError = (path, container, rejection) ->
    this.message = "promise returned from factory '#{path.id()}' was rejected with reason: #{rejection}"
    this.name = 'PromiseRejectedError'
    this.id = path.id()
    this.path = path.segments()
    this.container = container
    this.rejection = rejection
    if Error.captureStackTrace
      Error.captureStackTrace(this, this.constructor)
  hinoki.PromiseRejectedError.prototype = new Error

  hinoki.FactoryNotFunctionError = (path, container, factory) ->
    this.message = "factory '#{path.id()}' is not a function: #{factory}"
    this.name = 'FactoryNotFunctionError'
    this.id = path.id()
    this.path = path.segments()
    this.container = container
    this.factory = factory
    if Error.captureStackTrace
      Error.captureStackTrace(this, this.constructor)
  hinoki.FactoryNotFunctionError.prototype = new Error

  hinoki.FactoryReturnedUndefinedError = (path, container, factory) ->
    this.message = "factory '#{path.id()}' returned undefined"
    this.name = 'FactoryReturnedUndefinedError'
    this.id = path.id()
    this.path = path.segments()
    this.container = container
    this.factory = factory
    if Error.captureStackTrace
      Error.captureStackTrace(this, this.constructor)
  hinoki.FactoryReturnedUndefinedError.prototype = new Error

###################################################################################
# path

  hinoki.PathPrototype =
    toString: ->
      this.$segments.join ' <- '

    id: ->
      this.$segments[0]

    segments: ->
      this.$segments

    concat: (otherValue) ->
      otherPath = hinoki.castPath otherValue
      segments = this.$segments.concat otherPath.$segments
      hinoki.newPath segments

    isCyclic: ->
      hinoki.arrayOfStringsHasDuplicates this.$segments

  hinoki.newPath = (segments) ->
      id = Object.create hinoki.PathPrototype
      id.$segments = segments
      id

  hinoki.castPath = (value) ->
      if hinoki.PathPrototype.isPrototypeOf value
        value
      else if 'string' is typeof value
        hinoki.newPath [value]
      else if Array.isArray value
        hinoki.newPath value
      else
        throw new Error "value #{value} can not be cast to id"

###################################################################################
# util

  hinoki.isObject = (x) ->
    x is Object(x)

  hinoki.isThenable = (x) ->
    module.exports.isObject(x) and 'function' is typeof x.then

  hinoki.isUndefined =  (x) ->
    'undefined' is typeof x

  hinoki.isNull = (x) ->
    null is x

  hinoki.isExisting = (x) ->
    x?

  hinoki.identity = (x) ->
    x

  # calls fun for the values in array. returns the first
  # value returned by transform for which predicate returns true.
  # otherwise returns sentinel.

  hinoki.some = (
    array
    iterator = module.exports.identity
    predicate = module.exports.isExisting
    sentinel = undefined
  ) ->
    i = 0
    length = array.length
    while i < length
      result = iterator array[i]
      if predicate result
        return result
      i++
    return sentinel

  # returns whether an array of strings contains duplicates.
  #
  # complexity: O(n) since hash lookup is O(1)

  hinoki.arrayOfStringsHasDuplicates = (array) ->
    i = 0
    length = array.length
    valuesSoFar = {}
    while i < length
      value = array[i]
      if Object.prototype.hasOwnProperty.call valuesSoFar, value
        return true
      valuesSoFar[value] = true
      i++
    return false

  # coerces `arg` into an array.
  #
  # returns `arg` if it is an array.
  # returns `[arg]` otherwise.
  # returns `[]` if `arg` is null.
  #
  # example:
  # arrayify 'a'
  # => ['a']

  hinoki.arrayify = (arg) ->
    if Array.isArray arg
      return arg
    unless arg?
      return []
    [arg]

  # returns the first sequence of elements in `xs` which starts with `x`
  #
  # example:
  # startingWith ['a', 'b', 'c', 'd'], 'c'
  # => ['c', 'd']

  hinoki.startingWith = (xs, x) ->
    index = xs.indexOf x
    if index is -1
      return []
    xs.slice index

  # example:
  # parseFunctionArguments (a, b c) ->
  # => ['a', 'b‘, 'c']

  hinoki.parseFunctionArguments = (fun) ->
    unless 'function' is typeof fun
      throw new Error 'argument must be a function'

    string = fun.toString()

    argumentPart = string.slice(string.indexOf('(') + 1, string.indexOf(')'))

    dependencies = argumentPart.match(/([^\s,]+)/g)

    if dependencies
      dependencies
    else
      []

  hinoki.getIdsToInject = (factory) ->
    if factory.$inject?
      factory.$inject
    else
      hinoki.parseFunctionArguments factory

  return hinoki

###################################################################################
# node or browser?

isNode = module?.exports?

if isNode
  # node!
  module.exports = newHinoki require('bluebird')
else
  # browser!
  unless window.Promise?
    throw new Error 'hinoki requires Promise global by bluebird'
  window.hinoki = newHinoki window.Promise
