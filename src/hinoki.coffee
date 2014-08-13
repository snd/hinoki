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
      Promise.all(oneOrManyNamesOrPaths).map (nameOrPath) ->
        hinoki.getOne containers, nameOrPath, debug
    else
      hinoki.getOne containers, oneOrManyNamesOrPaths, debug

  hinoki.getOne = (containers, nameOrPath, debug) ->
    path = hinoki.castPath nameOrPath

    result = hinoki.resolveInContainers containers, path, debug

    unless result?
      # we are out of luck: the factory could not be found
      error = new hinoki.UnresolvableFactoryError path, containers[0]
      return Promise.reject error

    if result instanceof Error
      return Promise.reject result

    unless hinoki.isUndefined result.value
      debug? {
        event: 'valueFound'
        path: path.segments()
        result: result
      }
      return Promise.resolve result.value

    # no value available.
    # we've got a factory.
    # let's check for cycles first since
    # we can't use the factory if the path contains a cycle.

    if path.isCyclic()
      error = new hinoki.CircularDependencyError path, result.container
      return Promise.reject error

    # no cycle - yeah!

    unless 'function' is typeof result.factory
      # we are out of luck: the resolver didn't return a function
      # TODO call with result.name here
      return Promise.reject new hinoki.FactoryNotFunctionError path, result.container, result.factory

    debug? {
      event: 'factoryResolved'
      path: path.segments()
      result: result
    }

    # if the value is already being constructed
    # wait for that instead of starting a second construction.
    # a factory must only be called exactly once per container.

    # from here on we use the name and container returned by the resolver
    # which might differ from what was originally searched

    underConstruction = result.container.underConstruction?[result.name]

    if underConstruction?
      debug? {
        event: 'valueUnderConstruction'
        name: path.name()
        path: path.segments()
        value: underConstruction
        container: result.container
      }
      return underConstruction

    # there is no value under construction. lets make one!

    # lets resolve the dependencies of the factory

    remainingContainers = hinoki.startingWith containers, result.container
    # if a resolver returns a container that is not in the original
    # container chain then remainingContainers is [].
    # correct for that.
    if remainingContainers.length is 0
      remainingContainers = [result.container]

    dependencyNames = hinoki.getNamesToInject result.factory

    dependencyPaths = dependencyNames.map (x) ->
      hinoki.castPath(x).concat path

    dependenciesPromise = hinoki.get remainingContainers, dependencyPaths, debug

    factoryCallResultPromise = dependenciesPromise.then (dependencyValues) ->

      # the dependencies are ready
      # and we can finally call the factory

      hinoki.callFactory result.container, path, result.factory, dependencyValues, debug

    result.container.underConstruction ?= {}
    result.container.underConstruction[result.name] = factoryCallResultPromise

    factoryCallResultPromise.then (value) ->
      # note that a null value is allowed!
      if hinoki.isUndefined value
        error = new hinoki.FactoryReturnedUndefinedError path, result.container, result.factory
        return Promise.reject error
      # value is fully constructed
      cache = result.container.cache or hinoki.defaultCache
      cache
        container: result.container
        name: result.name
        value: value
      delete result.container.underConstruction[result.name]
      return value

  ###################################################################################
  # call factory

  # normalizes sync and async values returned by factories
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

  hinoki.resolveInContainer = (container, nameOrPath, debug) ->
    path = hinoki.castPath nameOrPath
    name = path.name()

    defaultResolver = (query) ->
      result = hinoki.defaultResolver query
      debug? {
        event: 'defaultResolverCalled'
        query: query
        result: result
      }
      return result

    resolvers = container.resolvers || []
    accum = (inner, resolver) ->
      (query) ->
        result = resolver query, inner, debug
        debug? {
          event: 'resolverCalled'
          query: query
          result: result
        }
        return result
    resolve = resolvers.reduceRight accum, defaultResolver
    return resolve {
      container: container
      name: name
    }

  hinoki.resolveInContainers = (containers, nameOrPath, debug) ->
    path = hinoki.castPath nameOrPath

    hinoki.some containers, (container) ->
      hinoki.resolveInContainer container, path, debug

  ###################################################################################
  # default

  hinoki.defaultResolver = (query) ->
      value = query.container.values?[query.name]
      unless hinoki.isUndefined value
        return {
          value: value
          name: query.name
          container: query.container
        }

      factory = query.container.factories?[query.name]
      unless factory?
        return

      # add $inject such that parseFunctionArguments is called only once per factory
      if not factory.$inject? and 'function' is typeof factory
        factory.$inject = hinoki.parseFunctionArguments factory

      return {
        factory: factory
        name: query.name
        container: query.container
      }

  hinoki.defaultCache = (options) ->
    options.container.values ?= {}
    options.container.values[options.name] = options.value

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
