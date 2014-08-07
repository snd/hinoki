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

  hinoki.get = (oneOrManyContainers, oneOrManyNamesOrPaths, debug) ->
    containers = hinoki.arrayify oneOrManyContainers

    if containers.length is 0
      throw new Error 'at least 1 container is required'

    if Array.isArray oneOrManyNamesOrPaths
      hinoki.getMany containers, oneOrManyNamesOrPaths, debug
    else
      hinoki.getOne containers, oneOrManyNamesOrPaths, debug

  hinoki.getMany = (containers, namesOrPaths, debug) ->
    Promise.all(namesOrPaths).map (nameOrPath) ->
      hinoki.getOne containers, nameOrPath, debug

  hinoki.getOne = (containers, nameOrPath, debug) ->
    path = hinoki.castPath nameOrPath

    valueResult = hinoki.resolveValueInContainers containers, path

    if valueResult?
      debug? {
        event: 'valueFound'
        name: path.name()
        path: path.segments()
        value: valueResult.value
        container: valueResult.container
      }
      return Promise.resolve valueResult.value

    # no value available. we need a factory.
    # let's check for cycles first since
    # we can't use a factory if the path contains a cycle.

    if path.isCyclic()
      error = new hinoki.CircularDependencyError path, containers[0]
      return Promise.reject error

    # no cycle - yeah!
    # lets find the container that can give us a factory

    # resolveFactoryInContainers has the opportunity
    # to return an error through a rejected promise that
    # is returned by getOrCreateManyValues unchanged
    factoryResult = hinoki.resolveFactoryInContainers containers, path, debug

    if factoryResult instanceof Error
      return Promise.reject factoryResult

    unless factoryResult?
      # we are out of luck: the factory could not be found
      error = new hinoki.UnresolvableFactoryError path, containers[0]
      return Promise.reject error

    # we've got a factory

    {factory, container} = factoryResult

    debug? {
      event: 'factoryFound'
      name: path.name()
      path: path.segments()
      factory: factory
      container: container
    }

    # if the value is already being constructed
    # wait for that instead of starting a second construction.
    # a factory must only be called exactly once per container.

    underConstruction = container.underConstruction?[path.name()]

    if underConstruction?
      debug? {
        event: 'valueUnderConstruction'
        name: path.name()
        path: path.segments()
        value: underConstruction
        container: container
      }
      return underConstruction

    # there is no value under construction. lets make one!

    # lets resolve the dependencies of the factory

    remainingContainers = hinoki.startingWith containers, container

    dependencyNames = hinoki.getNamesToInject factory

    dependencyPaths = dependencyNames.map (x) ->
      hinoki.castPath(x).concat path

    # TODO handle optional dependencies here
    # maybe through the paths?
    # return nulls

    dependenciesPromise = hinoki.get remainingContainers, dependencyPaths, debug

    factoryCallResultPromise = dependenciesPromise.then (dependencyValues) ->

      # the dependencies are ready
      # and we can finally call the factory

      hinoki.callFactory container, path, factory, dependencyValues, debug

    container.underConstruction ?= {}
    container.underConstruction[path.name()] = factoryCallResultPromise

    factoryCallResultPromise.then (value) ->
      # note that a null value is allowed!
      if hinoki.isUndefined value
        error = new hinoki.FactoryReturnedUndefinedError path, container, factory
        return Promise.reject error
      # value is fully constructed
      container.values ?= {}
      container.values[path.name()] = value
      delete container.underConstruction[path.name()]
      value

  ###################################################################################
  # call factory

  hinoki.callFactory = (container, nameOrPath, factory, dependencyValues, debug) ->
    path = hinoki.castPath nameOrPath
    try
      valueOrPromise = factory.apply null, dependencyValues
    catch exception
      error = new hinoki.ExceptionInFactoryError path, container, exception
      return Promise.reject error

    unless hinoki.isThenable valueOrPromise
      # valueOrPromise is not a promise but an value
      debug? {
        event: 'valueCreated',
        name: path.name()
        path: path.segments()
        value: valueOrPromise
        factory: factory
        container: container
      }
      return Promise.resolve valueOrPromise

    # valueOrPromise is a promise

    debug? {
      event: 'promiseCreated'
      name: path.name()
      path: path.segments()
      promise: valueOrPromise
      container: container
      factory: factory
    }

    Promise.resolve(valueOrPromise)
      .then (value) ->
        debug? {
          event: 'promiseResolved'
          name: path.name()
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

  hinoki.resolveFactoryInContainer = (container, nameOrPath, debug) ->
    path = hinoki.castPath nameOrPath
    name = path.name()

    defaultResolver = (container, name) ->
      factory = hinoki.defaultFactoryResolver container, name
      debug? {
        event: 'defaultFactoryResolverCalled'
        calledWithName: name
        calledWithContainer: container
        returnedFactory: factory
      }
      return factory

    resolvers = container.factoryResolvers || []
    accum = (inner, resolver) ->
      (container, name) ->
        factory = resolver container, name, inner, debug
        debug? {
          event: 'factoryResolverCalled'
          resolver: resolver
          calledWithName: name
          calledWithContainer: container
          returnedFactory: factory
        }
        return factory
    resolve = resolvers.reduceRight accum, defaultResolver
    return resolve container, name

  hinoki.resolveFactoryInContainers = (containers, nameOrPath, debug) ->
    path = hinoki.castPath nameOrPath

    hinoki.some containers, (container) ->
      factory = hinoki.resolveFactoryInContainer container, path, debug

      unless factory?
        return

      unless 'function' is typeof factory
        # we are out of luck: the resolver didn't return a function
        return new hinoki.FactoryNotFunctionError path, container, factory

      {
        factory: factory
        container: container
      }

  ###################################################################################
  # functions that resolve values

  hinoki.resolveValueInContainer = (container, nameOrPath, debug) ->
    path = hinoki.castPath nameOrPath
    name = path.name()

    defaultResolver = (container, name) ->
      value = hinoki.defaultValueResolver container, name
      debug? {
        event: 'defaultValueResolverCalled'
        calledWithName: name
        calledWithContainer: container
        returnedValue: value
      }
      return value

    resolvers = container.valueResolvers || []
    accum = (inner, resolver) ->
      (container, name) ->
        value = resolver container, name, inner, debug
        debug? {
          event: 'valueResolverCalled'
          resolver: resolver
          calledWithName: name
          calledWithContainer: container
          returnedValue: value
        }
        return value
    resolve = resolvers.reduceRight accum, defaultResolver
    return resolve container, name

  hinoki.resolveValueInContainers = (containers, nameOrPath, debug) ->
    path = hinoki.castPath nameOrPath

    hinoki.some containers, (container) ->
      value = hinoki.resolveValueInContainer container, path, debug

      # note that null values are passed on
      if hinoki.isUndefined value
        return

      {
        value: value
        container: container
      }

  ###################################################################################
  # shorthand for container construction

  hinoki.newContainer = (factories = {}, values = {}) ->
    {
      factories: factories
      values: values
    }

  ###################################################################################
  # default resolvers

  hinoki.defaultValueResolver = (container, name) ->
    container.values?[name]

  hinoki.defaultFactoryResolver = (container, name) ->
    factory = container.factories?[name]
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
    this.type = 'CircularDependencyError'
    this.name = path.name()
    this.path = path.segments()
    this.container = container
    if Error.captureStackTrace
      Error.captureStackTrace(this, this.constructor)
  hinoki.CircularDependencyError.prototype = new Error

  hinoki.UnresolvableFactoryError = (path, container) ->
    this.message = "unresolvable factory '#{path.name()}' (#{path.toString()})"
    this.type = 'UnresolvableFactoryError'
    this.name = path.name()
    this.path = path.segments()
    this.container = container
    if Error.captureStackTrace
      Error.captureStackTrace(this, this.constructor)
  hinoki.UnresolvableFactoryError.prototype = new Error

  hinoki.ExceptionInFactoryError = (path, container, exception) ->
    this.message = "exception in factory '#{path.name()}': #{exception}"
    this.type = 'ExceptionInFactoryError'
    this.name = path.name()
    this.path = path.segments()
    this.container = container
    this.exception = exception
    if Error.captureStackTrace
      Error.captureStackTrace(this, this.constructor)
  hinoki.ExceptionInFactoryError.prototype = new Error

  hinoki.PromiseRejectedError = (path, container, rejection) ->
    this.message = "promise returned from factory '#{path.name()}' was rejected with reason: #{rejection}"
    this.type = 'PromiseRejectedError'
    this.name = path.name()
    this.path = path.segments()
    this.container = container
    this.rejection = rejection
    if Error.captureStackTrace
      Error.captureStackTrace(this, this.constructor)
  hinoki.PromiseRejectedError.prototype = new Error

  hinoki.FactoryNotFunctionError = (path, container, factory) ->
    this.message = "factory '#{path.name()}' is not a function: #{factory}"
    this.type = 'FactoryNotFunctionError'
    this.name = path.name()
    this.path = path.segments()
    this.container = container
    this.factory = factory
    if Error.captureStackTrace
      Error.captureStackTrace(this, this.constructor)
  hinoki.FactoryNotFunctionError.prototype = new Error

  hinoki.FactoryReturnedUndefinedError = (path, container, factory) ->
    this.message = "factory '#{path.name()}' returned undefined"
    this.type = 'FactoryReturnedUndefinedError'
    this.name = path.name()
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

    name: ->
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
    path = Object.create hinoki.PathPrototype
    path.$segments = segments
    path

  hinoki.castPath = (value) ->
    if hinoki.PathPrototype.isPrototypeOf value
      value
    else if 'string' is typeof value
      hinoki.newPath [value]
    else if Array.isArray value
      hinoki.newPath value
    else
      throw new Error "value #{value} can not be cast to name"

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

  hinoki.getNamesToInject = (factory) ->
    if factory.$inject?
      factory.$inject
    else
      hinoki.parseFunctionArguments factory
