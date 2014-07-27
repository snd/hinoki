# do -> = module pattern in coffeescript
do ->
  hinoki = {}

  ###################################################################################
  # node.js or browser?

  if window?
    unless window.Promise?
      throw new Error 'hinoki requires Promise global by bluebird to be present'
    Promise = window.Promise
    window.hinoki = hinoki
  else if module?.exports?
    Promise = require 'bluebird'
    module.exports = hinoki
  else
    throw new Error 'either the `window` global or the `module.exports` global must be present'

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

    # resolveValueInContainers has the opportunity
    # to return an error through a rejected promise that
    # is returned by getOrCreateManyValues unchanged
    valueResultPromise = hinoki.resolveValueInContainers containers, path

    if valueResultPromise?
      return valueResultPromise.then (valueResult) ->
        debug? {
          event: 'valueFound'
          id: path.id()
          path: path.segments()
          value: valueResult.value
          resolver: valueResult.resolver
          container: valueResult.container
        }
        valueResult.value

    # no value available. we need a factory.
    # let's check for cycles first since
    # we can't use a factory if the id contains a cycle.

    if path.isCyclic()
      error = new hinoki.CircularDependencyError path, containers[0]
      return Promise.reject error

    # no cycle - yeah!
    # lets find the container that can give us a factory

    # resolveFactoryInContainers has the opportunity
    # to return an error through a rejected promise that
    # is returned by getOrCreateManyValues unchanged
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

      # if the value is already being constructed
      # wait for that instead of starting a second construction.
      # a factory must only be called exactly once per container.

      underConstruction = container.underConstruction?[path.id()]

      if underConstruction?
        debug? {
          event: 'valueUnderConstruction'
          id: path.id()
          path: path.segments()
          value: underConstruction
          container: container
        }
        return underConstruction

      # there is no value under construction. lets make one!

      # lets resolve the dependencies of the factory

      remainingContainers = hinoki.startingWith containers, container

      dependencyIds = hinoki.getIdsToInject factory

      dependencyIds = dependencyIds.map (x) ->
        hinoki.castPath(x).concat path

      dependenciesPromise = hinoki.get remainingContainers, dependencyIds, debug

      valuePromise = dependenciesPromise.then (dependencyValues) ->

        # the dependencies are ready
        # and we can finally call the factory

        hinoki.callFactory container, path, factory, dependencyValues, debug

      container.underConstruction ?= {}
      container.underConstruction[path.id()] = valuePromise

      valuePromise.then (value) ->
        if hinoki.isUndefined value
          error = new hinoki.FactoryReturnedUndefinedError path, container, factory
          return Promise.reject error
        # value is fully constructed
        container.values ?= {}
        container.values[path.id()] = value
        delete container.underConstruction[path.id()]
        value

  ###################################################################################
  # call factory

  hinoki.callFactory = (container, idOrPath, factory, dependencyValues, debug) ->
    path = hinoki.castPath idOrPath
    try
      valueOrPromise = factory.apply null, dependencyValues
    catch exception
      error = new hinoki.ExceptionInFactoryError path, container, exception
      return Promise.reject error

    unless hinoki.isThenable valueOrPromise
      # valueOrPromise is not a promise but an value
      debug? {
        event: 'valueCreated',
        id: path.id()
        path: path.segments()
        value: valueOrPromise
        factory: factory
        container: container
      }
      return Promise.resolve valueOrPromise

    # valueOrPromise is a promise

    debug? {
      event: 'promiseCreated'
      id: path.id()
      path: path.segments()
      promise: valueOrPromise
      container: container
      factory: factory
    }

    Promise.resolve(valueOrPromise)
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

  # returns either null or a promise that resolves to {factory: }

  hinoki.resolveFactoryInContainer = (container, idOrPath) ->
    path = hinoki.castPath idOrPath
    id = path.id()

    defaultResolve = ->
      hinoki.defaultFactoryResolver container, id

    resolve =
      if container.factoryResolvers?
        accum = (inner, resolver) ->
          -> resolver container, id, inner
        container.factoryResolvers.reduceRight accum, defaultResolve
      else
        defaultResolve

    factory = resolve()

    # this resolver can't resolve the factory
    unless factory?
      return

    unless 'function' is typeof factory
      # we are out of luck: the resolver didn't return a function
      error = new hinoki.FactoryNotFunctionError path, container, factory
      return Promise.reject error

    Promise.resolve
      factory: factory

  # returns either null or a promise that resolves to {container: , factory: }

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
  # functions that resolve values

  # returns either null or a promise that resolves to {value: }

  hinoki.resolveValueInContainer = (container, idOrPath) ->
    path = hinoki.castPath idOrPath
    id = path.id()

    defaultResolve = ->
      hinoki.defaultValueResolver container, id

    resolve =
      if container.valueResolvers?
        accum = (inner, resolver) ->
          -> resolver container, id, inner
        container.valueResolvers.reduceRight accum, defaultResolve
      else
        defaultResolve

    value = resolve()

    unless value?
      return

    Promise.resolve
      value: value

  # returns either null or a promise that resolves to {container: , value: }

  hinoki.resolveValueInContainers = (containers, idOrPath) ->
    path = hinoki.castPath idOrPath

    hinoki.some containers, (container) ->
      promise = hinoki.resolveValueInContainer container, path

      unless promise?
        return

      promise.then (result) ->
        result.container = container
        result

  ###################################################################################
  # shorthand for container construction

  hinoki.newContainer = (factories, values) ->
    {
      factories: factories
      values: values
    }

  ###################################################################################
  # default resolvers

  hinoki.defaultValueResolver = (container, id) ->
    container.values?[id]

  hinoki.defaultFactoryResolver = (container, id) ->
    factory = container.factories?[id]
    unless factory?
      return

    # add $inject such that parseFunctionArguments is called only once per factory
    if not factory.$inject? and 'function' is typeof factory
      factory.$inject = hinoki.parseFunctionArguments factory

    return factory

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
    hinoki.isObject(x) and 'function' is typeof x.then

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
    iterator = hinoki.identity
    predicate = hinoki.isExisting
    sentinel = undefined
  ) ->
    i = 0
    length = array.length
    while i < length
      result = iterator array[i], i
      if predicate result, i
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
