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
    containers = hinoki.coerceToArray oneOrManyContainers

    if containers.length is 0
      throw new Error 'at least 1 container is required'

    if Array.isArray oneOrManyNamesOrPaths
      Promise.all(oneOrManyNamesOrPaths).map (nameOrPath) ->
        hinoki.getOne containers, nameOrPath, debug
    else
      hinoki.getOne containers, oneOrManyNamesOrPaths, debug

  hinoki.getOne = (containers, nameOrPath, debug) ->
    path = hinoki.coerceToArray nameOrPath

    try
      resolution = hinoki.resolveInContainers containers, path, debug
    catch error
      return Promise.reject new hinoki.ErrorInResolversError path, containers, error

    # from here on we use the name and container returned by the resolver
    # (resolution.name and resolution.container)
    # which might differ from what was originally searched (path[0]).

    if resolution instanceof Error
      return Promise.reject new hinoki.ErrorInResolversError path, containers, resolution

    unless resolution?
      # we are out of luck: the factory could not be found
      return Promise.reject new hinoki.UnresolvableError path, containers

    resolutionErrors = hinoki.resolutionErrors resolution

    if resolutionErrors?
      return Promise.reject new hinoki.InvalidResolutionError path, resolution, resolutionErrors

    unless hinoki.isUndefined resolution.value
      debug? {
        event: 'valueWasResolved'
        path: path
        resolution: resolution
      }
      return Promise.resolve resolution.value

    # no value available.
    # we've got a factory.
    # let's check for cycles first since
    # we can't use the factory if the path contains a cycle.

    # TODO how to handle name change here

    if hinoki.arrayOfStringsHasDuplicates path
      return Promise.reject new hinoki.CircularDependencyError path, resolution

    # no cycle - yeah!

    debug? {
      event: 'factoryWasResolved'
      path: path
      resolution: resolution
    }

    nocache = resolution.nocache or resolution.factory.$nocache

    unless nocache
      # if the value is already being constructed
      # wait for that instead of starting a second construction.

      promiseAwaitingResolution = resolution.container.promisesAwaitingResolution?[resolution.name]

      if promiseAwaitingResolution?
        debug? {
          event: 'valueIsAlreadyAwaitingResolution'
          path: path
          resolution: resolution
          promise: promiseAwaitingResolution
        }
        return promiseAwaitingResolution

    # there is no value under construction. lets make one!

    # first lets resolve the dependencies of the factory

    remainingContainers = hinoki.startingWith containers, resolution.container

    dependencyNames = hinoki.getNamesToInject resolution.factory

    newPath = path.slice()
    newPath[0] = resolution.name

    dependencyPaths = dependencyNames.map (x) ->
      hinoki.coerceToArray(x).concat newPath

    # this code is reached synchronously from the start of the function call
    # without interleaving.

    dependenciesPromise = hinoki.get remainingContainers, dependencyPaths, debug

    factoryCallResultPromise = dependenciesPromise.then (dependencyValues) ->

      # the dependencies are ready!
      # we can finally call the factory!

      hinoki.callFactory resolution.container, newPath, resolution.factory, dependencyValues, debug

    # cache the promise.
    # this code is reached synchronously from the start of the function call
    # without interleaving.

    unless nocache
      resolution.container.promisesAwaitingResolution ?= {}
      resolution.container.promisesAwaitingResolution[resolution.name] = factoryCallResultPromise

    factoryCallResultPromise
      .then (value) ->
        # note that a null value is allowed!
        if hinoki.isUndefined value
          return Promise.reject new hinoki.FactoryReturnedUndefinedError newPath, resolution.container, resolution.factory

        # cache
        unless nocache
          resolution.container.values ?= {}
          resolution.container.values[resolution.name] = value

        return value
      .finally ->
        # whether success or error: remove promise from promise cache
        # this prevents errored promises from being reused
        # and allows further requests for the errored names to succeed
        unless nocache
          delete resolution.container.promisesAwaitingResolution[resolution.name]
          if Object.keys(resolution.container.promisesAwaitingResolution).length is 0
            delete resolution.container.promisesAwaitingResolution

  ###################################################################################
  # call factory

  # normalizes sync and async values returned by factories
  hinoki.callFactory = (container, nameOrPath, factory, dependencyValues, debug) ->
    path = hinoki.coerceToArray nameOrPath
    try
      valueOrPromise = factory.apply null, dependencyValues
    catch error
      return Promise.reject new hinoki.ThrowInFactoryError path, container, error

    unless hinoki.isThenable valueOrPromise
      # valueOrPromise is not a promise but an value
      debug? {
        event: 'valueWasCreated',
        path: path
        value: valueOrPromise
        factory: factory
        container: container
      }
      return Promise.resolve valueOrPromise

    # valueOrPromise is a promise

    debug? {
      event: 'promiseWasCreated'
      path: path
      promise: valueOrPromise
      container: container
      factory: factory
    }

    Promise.resolve(valueOrPromise)
      .then (value) ->
        debug? {
          event: 'promiseWasResolved'
          path: path
          value: value
          container: container
          factory: factory
        }
        return value
      .catch (rejection) ->
        Promise.reject new hinoki.PromiseRejectedError path, container, rejection

  ###################################################################################
  # functions that resolve factories

  hinoki.resolveInContainer = (container, nameOrPath, debug) ->
    path = hinoki.coerceToArray nameOrPath

    defaultResolver = (name) ->
      resolution = hinoki.defaultResolver name, container
      debug? {
        event: 'defaultResolverWasCalled'
        path: path
        container: container
        resolution: resolution
      }
      return resolution

    resolvers = hinoki.coerceToArray(container.resolvers || [])
    accum = (inner, resolver) ->
      (name) ->
        resolution = resolver name, container, inner, debug
        debug? {
          event: 'customResolverWasCalled'
          resolver: resolver
          path: path
          container: container
          resolution: resolution
        }
        return resolution
    resolve = resolvers.reduceRight accum, defaultResolver

    resolution = resolve path[0]

    if resolution? and 'object' is typeof resolution
      resolution.container = container

    return resolution

  hinoki.resolveInContainers = (containers, nameOrPath, debug) ->
    path = hinoki.coerceToArray nameOrPath

    hinoki.some containers, (container) ->
      hinoki.resolveInContainer container, path, debug

  ###################################################################################
  # resolution

  hinoki.resolutionErrors = (resolution) ->
    errors = []
    unless 'object' is typeof resolution
      errors.push 'must be an object'

    unless resolution?.name? and 'string' is typeof resolution?.name
      errors.push "must have the 'name' property which is a string"

    isValue = not hinoki.isUndefined resolution?.value
    isFactory = resolution?.factory?

    unless isValue or isFactory
      errors.push "must have either the 'value' or the 'factory' property"
    else if isValue and isFactory
      errors.push "must have either the 'value' or the 'factory' property - not both"
    else if isFactory and 'function' isnt typeof resolution.factory
      errors.push "the 'factory' property must be a function"

    if errors.length is 0 then null else errors

  hinoki.defaultResolver = (name, container) ->
    value = container.values?[name]
    unless hinoki.isUndefined value
      return {
        value: value
        name: name
      }

    factory = container.factories?[name]
    unless factory?
      return

    # add $inject such that parseFunctionArguments is called only once per factory
    if not factory.$inject? and 'function' is typeof factory
      factory.$inject = hinoki.parseFunctionArguments factory

    return {
      factory: factory
      name: name
    }

  ###################################################################################
  # errors

  hinoki.inherits = (constructor, superConstructor) ->
    if 'function' is typeof Object.create
      constructor.prototype = Object.create(superConstructor.prototype)
      constructor.prototype.constructor = constructor
    else
      # where there is no Object.create we use a proxy constructor
      # to make a new object that has super constructor as its prototype
      # and make it the prototype of constructor
      proxyConstructor = ->
      proxyConstructor.prototype = superConstructor.prototype
      constructor.prototype = new proxyConstructor
      constructor.prototype.constructor = constructor

  # constructors for errors which are catchable with bluebirds `catch`

  # the base error for all other hinoki errors
  # not to be instantiated directly
  hinoki.BaseError = ->
  hinoki.inherits hinoki.BaseError, Error

  hinoki.ErrorInResolversError = (path, containers, error) ->
    this.name = 'ErrorInResolversError'
    this.message = "error in resolvers for '#{path[0]}' (#{hinoki.pathToString path}). original error: #{error.toString()}"
    if Error.captureStackTrace?
      # second argument excludes the constructor from inclusion in the stack trace
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.containers = containers
    this.error = error
    return

  hinoki.inherits hinoki.ErrorInResolversError, hinoki.BaseError

  hinoki.UnresolvableError = (path, container) ->
    this.name = 'UnresolvableError'
    this.message = "unresolvable name '#{path[0]}' (#{hinoki.pathToString path})"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.container = container
    return

  hinoki.inherits hinoki.UnresolvableError, hinoki.BaseError

  hinoki.InvalidResolutionError = (path, resolution, errors) ->
    this.name = 'InvalidResolutionError'
    lines = errors
    lines.unshift "errors in resolution returned by resolvers for '#{path[0]}' (#{hinoki.pathToString path}):"
    this.message = lines.join '\n'
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.resolution = resolution
    return

  hinoki.inherits hinoki.InvalidResolutionError, hinoki.BaseError

  hinoki.CircularDependencyError = (path, containers) ->
    this.name = 'CircularDependencyError'
    this.message = "circular dependency #{hinoki.pathToString path}"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.containers = containers
    return

  hinoki.inherits hinoki.CircularDependencyError, hinoki.BaseError

  hinoki.ThrowInFactoryError = (path, container, error) ->
    this.name = 'ThrowInFactoryError'
    this.message = "error in factory for '#{path[0]}'. original error: #{error.toString()}"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.container = container
    this.error = error
    return

  hinoki.inherits hinoki.ThrowInFactoryError, hinoki.BaseError

  hinoki.FactoryReturnedUndefinedError = (path, container, factory) ->
    this.name = 'FactoryReturnedUndefinedError'
    this.message = "factory for '#{path[0]}' returned undefined"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.container = container
    this.factory = factory
    return

  hinoki.inherits hinoki.FactoryReturnedUndefinedError, hinoki.BaseError

  hinoki.PromiseRejectedError = (path, container, error) ->
    this.name = 'PromiseRejectedError'
    this.message = "promise returned from factory for '#{path[0]}' was rejected. original error: #{error.toString()}"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.container = container
    this.error = error
    return

  hinoki.inherits hinoki.PromiseRejectedError, hinoki.BaseError

  ###################################################################################
  # path

  hinoki.pathToString = (path) ->
    path.join ' <- '

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

  # calls iterator for the values in array in sequence (with the index as the second argument).
  # returns the first value returned by iterator for which predicate returns true.
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
  # coerceToArray 'a'
  # => ['a']

  hinoki.coerceToArray = (arg) ->
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
