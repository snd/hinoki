((root, factory) ->
  # amd
  if ('function' is typeof define) and define.amd?
    define(['bluebird'], factory)
  # commonjs
  else if exports?
    module.exports = factory(require('bluebird'))
  # other
  else
    root.hinoki = factory(root.Promise)
)(this, (Promise) ->

  ###################################################################################
  # get

  # polymorphic
  hinoki = (oneOrManyLifetimes, nameOrNamesOrFunction) ->
    lifetimes = hinoki.coerceToArray oneOrManyLifetimes

    if lifetimes.length is 0
      throw new Error 'at least 1 lifetime is required'

    if 'function' is typeof nameOrNamesOrFunction
      return hinoki.many(
        lifetimes
        0
        hinoki.getNamesToInject(nameOrNamesOrFunction).map(hinoki.coerceToArray)
      ).spread(nameOrNamesOrFunction)

    if Array.isArray nameOrNamesOrFunction
      paths = hinoki.coerceToArray(nameOrNamesOrFunction).map(hinoki.coerceToArray)
      return hinoki.many lifetimes, 0, paths

    hinoki.one lifetimes, 0, hinoki.coerceToArray(nameOrNamesOrFunction)

  # getValues
  hinoki.many = (lifetimes, lifetimeOffset, paths) ->
      Promise.all paths.map (path) ->
        hinoki.one lifetimes, lifetimeOffset, path

  # getValue
  hinoki.one = (lifetimes, lifetimeOffset, path) ->
    name = path[0]

    # these may be set at the end of the following loop
    lifetime = undefined
    factorySource = undefined
    factory = undefined

    newLifetimeOffset = lifetimeOffset - 1
    lifetimeLength = lifetimes.length
    while ++newLifetimeOffset < lifetimeLength
      lifetime = lifetimes[newLifetimeOffset]
      value = lifetime.values?[name]
      # null is allowed as a value
      unless hinoki.isUndefined value
        lifetime.debug? {
          event: 'valueWasResolved'
          path: path
          value: value
        }
        return Promise.resolve value
      promise = lifetime.promisesAwaitingResolution?[name]
      if promise?
        # if the value is already being constructed
        # wait for that instead of starting a second construction.
        lifetime.debug? {
          event: 'valueIsAlreadyAwaitingResolution'
          path: path
          promise: promise
        }
        return promise
      if Array.isArray lifetime.factories
        factorySourceIndex = -1
        factorySourceLength = lifetime.factories.length
        while ++factorySourceIndex < factorySourceLength
          factorySource = lifetime.factories[factorySourceIndex]
          # factory source function
          if 'function' is typeof factorySource
            factory = factorySource(name)
          # factory source object
          else
            factory = factorySource[name]
          if factory?
            break
        if factory?
          break

      factorySource = lifetime.factories
      factory = factorySource?[name]
      if factory?
        break

    unless factory?
      # we are out of luck: the factory could not be found
      return Promise.reject new hinoki.UnresolvableError path, lifetimes

    # we've got a factory.
    # let's check for cycles first since
    # we can't use the factory if the path contains a cycle.

    if hinoki.arrayOfStringsHasDuplicates path
      return Promise.reject new hinoki.CircularDependencyError path, lifetime, factory

    # no cycle - yeah!

    lifetime.debug? {
      event: 'factoryWasResolved'
      path: path
      factorySource: factorySource
      factory: factory
    }

    # lets make a value

    # first lets resolve the dependencies of the factory

    # TODO this isnt really useful when factorySource is a function
    # TODO separate sources property ?
    dependencyNames = hinoki.getAndCacheNamesToInject factory

    newPath = path.slice()
    newPath[0] = name

    dependencyPaths = dependencyNames.map (x) ->
      hinoki.coerceToArray(x).concat newPath

    # this code is reached synchronously from the start of the function call
    # without interleaving.

    dependenciesPromise =
      if dependencyPaths.length isnt 0
        hinoki.many lifetimes, newLifetimeOffset, dependencyPaths
      else
        Promise.resolve([])

    factoryCallResultPromise = dependenciesPromise.then (dependencyValues) ->
      # the dependencies are ready!
      # we can finally call the factory!

      hinoki.callFactory lifetime, newPath, factory, dependencyValues

    # cache the promise.
    # this code is reached synchronously from the start of the function call
    # without interleaving.
    # its important that the factoryCallResultPromise is added
    # to promisesAwaitingResolution before the factory is actually called !

    unless factory.$nocache
      lifetime.promisesAwaitingResolution ?= {}
      lifetime.promisesAwaitingResolution[name] = factoryCallResultPromise

    factoryCallResultPromise
      .then (value) ->
        # note that a null value is allowed!
        if hinoki.isUndefined value
          return Promise.reject new hinoki.FactoryReturnedUndefinedError newPath, lifetime, factory

        # cache
        unless factory.$nocache
          lifetime.values ?= {}
          lifetime.values[name] = value

        return value
      .finally ->
        # whether success or error: remove promise from promise cache
        # this prevents errored promises from being reused
        # and allows further requests for the errored names to succeed
        unless factory.$nocache
          delete lifetime.promisesAwaitingResolution[name]
          if Object.keys(lifetime.promisesAwaitingResolution).length is 0
            delete lifetime.promisesAwaitingResolution

  ###################################################################################
  # call factory

  # normalizes sync and async values returned by factories
  hinoki.callFactory = (lifetime, path, factory, dependencyValues) ->
    try
      valueOrPromise = factory.apply null, dependencyValues
    catch error
      return Promise.reject new hinoki.ThrowInFactoryError path, lifetime, factory, error

    unless hinoki.isThenable valueOrPromise
      # valueOrPromise is not a promise but an value
      lifetime.debug? {
        event: 'valueWasCreated',
        path: path
        value: valueOrPromise
        factory: factory
      }
      return Promise.resolve valueOrPromise

    # valueOrPromise is a promise

    lifetime.debug? {
      event: 'promiseWasCreated'
      path: path
      promise: valueOrPromise
      factory: factory
    }

    Promise.resolve(valueOrPromise)
      .then (value) ->
        lifetime.debug? {
          event: 'promiseWasResolved'
          path: path
          value: value
          factory: factory
        }
        return value
      .catch (rejection) ->
        Promise.reject new hinoki.PromiseRejectedError path, lifetime, rejection

  ###################################################################################
  # errors

  hinoki.inherits = (constructor, superConstructor) ->
    if 'function' is typeof Object.create
      constructor.prototype = Object.create(superConstructor.prototype)
      constructor.prototype.constructor = constructor
    else
      # if there is no Object.create we use a proxyConstructor
      # to make a new object that has superConstructor as its prototype
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

  hinoki.UnresolvableError = (path, lifetime) ->
    this.name = 'UnresolvableError'
    this.message = "unresolvable name '#{path[0]}' (#{hinoki.pathToString path})"
    if Error.captureStackTrace?
      # second argument excludes the constructor from inclusion in the stack trace
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.lifetime = lifetime
    return

  hinoki.inherits hinoki.UnresolvableError, hinoki.BaseError

  hinoki.CircularDependencyError = (path, lifetime, factory) ->
    this.name = 'CircularDependencyError'
    this.message = "circular dependency #{hinoki.pathToString path}"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.lifetime = lifetime
    this.factory = factory
    return

  hinoki.inherits hinoki.CircularDependencyError, hinoki.BaseError

  hinoki.ThrowInFactoryError = (path, lifetime, factory, error) ->
    this.name = 'ThrowInFactoryError'
    this.message = "error in factory for '#{path[0]}'. original error: #{error.toString()}"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.lifetime = lifetime
    this.factory = factory
    this.error = error
    return

  hinoki.inherits hinoki.ThrowInFactoryError, hinoki.BaseError

  hinoki.FactoryReturnedUndefinedError = (path, lifetime, factory) ->
    this.name = 'FactoryReturnedUndefinedError'
    this.message = "factory for '#{path[0]}' returned undefined"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.lifetime = lifetime
    this.factory = factory
    return

  hinoki.inherits hinoki.FactoryReturnedUndefinedError, hinoki.BaseError

  hinoki.PromiseRejectedError = (path, lifetime, error) ->
    this.name = 'PromiseRejectedError'
    this.message = "promise returned from factory for '#{path[0]}' was rejected. original error: #{error.toString()}"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)

    this.path = path
    this.lifetime = lifetime
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

  hinoki.getAndCacheNamesToInject = (factory) ->
    if factory.$inject?
      factory.$inject
    else
      names = hinoki.parseFunctionArguments factory
      factory.$inject = names
      return names

  return hinoki
)
