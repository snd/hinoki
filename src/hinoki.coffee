((root, factory) ->
  # amd
  if ('function' is typeof define) and define.amd?
    define(['bluebird', 'lodash'], factory)
  # nodejs
  else if exports?
    module.exports = factory(
      require('bluebird')
      require('lodash')
      require('fs')
      require('path')
    )
  # other
  else
    root.hinoki = factory(root.Promise, root.lodash)
)(this, (Promise, _, fs, path) ->

################################################################################
# get

  # polymorphic
  hinoki = (arg1, arg2, arg3) ->
    source = hinoki.source arg1

    if arg3?
      lifetimes = hinoki.coerceToArray arg2
      nameOrNamesOrFunction = arg3
    else
      lifetimes = [{}]
      nameOrNamesOrFunction = arg2

    cacheTarget = 0

    if 'function' is typeof nameOrNamesOrFunction
      names = hinoki.getNamesToInject(nameOrNamesOrFunction)
      paths = names.map(hinoki.coerceToArray)
      return hinoki.getValuesInLifetimes(lifetimes, 0, paths, cacheTarget)
        .spread(nameOrNamesOrFunction)

    if Array.isArray nameOrNamesOrFunction
      names = hinoki.coerceToArray(nameOrNamesOrFunction)
      paths = names.map(hinoki.coerceToArray)
      return hinoki.getValuesInLifetimes lifetimes, 0, paths, cacheTarget

    path = hinoki.coerceToArray(nameOrNamesOrFunction)
    hinoki.getValueInLifetimes lifetimes, 0, path, cacheTarget

  # monomorphic
  hinoki.getValuesInLifetimes = (lifetimes, lifetimeStartIndex, paths, cacheTarget) ->
    Promise.all paths.map (path) ->
      hinoki.getValueInLifetimes lifetimes, lifetimeStartIndex, path, cacheTarget

  # monomorphic
  hinoki.getValueInLifetimes = (lifetimes, lifetimeStartIndex, path, cacheTarget) ->
    # try lifetimes in order
    index = lifetimeStartIndex - 1
    length = lifetimes.length
    while ++index < length
      result = hinoki.getValueInLifetime lifetimes, index, path, cacheTarget
      if result?
        return result
    Promise.reject new hinoki.UnresolvableError path, lifetimes

  # monomorphic
  hinoki.getValueInLifetime = (lifetimes, lifetimeIndex, path, cacheTarget) ->
    lifetime = lifetimes[lifetimeIndex]
    name = path[0]
    if lifetime.mapName?
      name = lifetime.mapName name

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

    hinoki.weNeedAFactory lifetimes, lifetimeIndex, path

  hinoki.getFactoryFromSource = (factorySource, name) ->
    # factory source function
    if 'function' is typeof factorySource
      return factorySource(name)
    # factory source object
    else
      return factorySource[name]

  # monomorphic
  hinoki.weNeedAFactory = (lifetimes, lifetimeIndex, path) ->
    lifetime = lifetimes[lifetimeIndex]
    unless lifetime.factories?
      return
    if Array.isArray lifetime.factories
      factorySources = lifetime.factories
    else
      factorySources = [lifetime.factories]

    factorySourceIndex = -1
    factorySourceLength = factorySources.length
    while ++factorySourceIndex < factorySourceLength
      factorySource = factorySources[factorySourceIndex]
      factory = hinoki.getFactoryFromSource factorySource, path[0]
      if factory?
        if lifetime.mapFactory?
          factory = lifetime.mapFactory factory
        return hinoki.weHaveAFactory lifetimes, lifetimeIndex, path, factorySource, factory

  # monomorphic
  hinoki.weHaveAFactory = (lifetimes, lifetimeIndex, path, factorySource, factory) ->
    lifetime = lifetimes[lifetimeIndex]

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

    dependencyNames = hinoki.getAndCacheNamesToInject factory

    newPath = path.slice()

    dependencyPaths = dependencyNames.map (x) ->
      hinoki.coerceToArray(x).concat newPath

    # this code is reached synchronously from the start of the function call
    # without interleaving.

    dependenciesPromise =
      if dependencyPaths.length isnt 0
        hinoki.getValuesInLifetimes lifetimes, lifetimeIndex, dependencyPaths
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
      lifetime.__promises ?= {}
      lifetime.__promises[path[0]] = factoryCallResultPromise

    factoryCallResultPromise
      .then (value) ->
        # note that a null value is allowed!
        if hinoki.isUndefined value
          return Promise.reject new hinoki.FactoryReturnedUndefinedError newPath, lifetime, factory

        # cache
        unless factory.$nocache
          lifetime.values ?= {}
          lifetime.values[path[0]] = value

        return value
      .finally ->
        # whether success or error: remove promise from promise cache
        # this prevents errored promises from being reused
        # and allows further requests for the errored names to succeed
        unless factory.$nocache
          delete lifetime.promisesAwaitingResolution[path[0]]
          if Object.keys(lifetime.promisesAwaitingResolution).length is 0
            delete lifetime.promisesAwaitingResolution

  hinoki.callFactoryFunction = (factoryFunction, dependencies) ->
    try
      valueOrPromise = factoryFunction.apply null, valuesOfDependencies
    catch error
      return Promise.reject new hinoki.ThrowInFactoryError path, lifetime, factoryFunction, error

  hinoki.callFactoryObjectArray = (factoryObject, dependenciesObject) ->
    iterator = (f) ->
      if 'function' is typeof f
        names = hinoki.getNamesToInject f
        dependencies = _.map names, (name) ->
          dependenciesObject[name]
        hinoki.callFactoryFunction f, dependencies
      else
        # supports nesting
        hinoki.callFactoryObjectArray(f, dependenciesObject)

    if Array.isArray factory
      Promise.all(factory).map(iterator)
    # object !
    else
      Promise.props _.mapValues factory, iterator

  # normalizes sync and async values returned by factories
  hinoki.callFactoryAndHandleResult = (lifetime, path, factory, dependencyValues) ->
    if 'function' is typeof factory
      valueOrPromise = hinoki.callFactoryFunction factory, dependencyValues
    else
      names = hinoki.getNamesToInject factory
      dependenciesObject = _.zipObject names, dependencyValues
      valueOrPromise = hinoki.callFactoryObjectArray factory, dependenciesObject

    # TODO also return directly if promise is already fulfilled
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

################################################################################
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

################################################################################
# path

  hinoki.pathToString = (path) ->
    path.join ' <- '

################################################################################
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
    hinoki.baseGetNamesToInject factory, false

  hinoki.baseGetNamesToInject = (factory, cache) ->
    if factory.__inject?
      return factory.__inject
    else if 'function' is typeof factory
      names = hinoki.parseFunctionArguments factory
      if cache
        factory.__inject = names
      return names
    else if Array.isArray factory or 'object' is typeof factory
      namesSet = {}
      _.forEach factory, (subFactory) ->
        subNames = hinoki.baseGetNamesToInject(subFactory, cache)
        _.forEach subNames, (subName) ->
          namesSet[subName] = true
      names = Object.keys(namesSet)
      if cache
        factory.__inject = names
      return names
    else
      throw new Error 'factory has to be a function, object of factories or array of factories'

################################################################################
# functions for working with sources

  # returns an object containing all the exported properties
  # of all `*.js` and `*.coffee` files in `filepath`.
  # if `filepath` is a directory recurse into every file and subdirectory.

  if fs? and path?
    hinoki.requireSource = (filepath) ->
      unless 'string' is typeof filepath
        throw new Error 'argument must be a string'
      hinoki.source.baseRequire filepath, {}

    # TODO call this something like fromExports
    hinoki.baseRequireSource = (filepath, object) ->
      stat = fs.statSync(filepath)
      if stat.isFile()
        extension = path.extname(filepath)

        if extension isnt '.js' and extension isnt '.coffee'
          return

        # coffeescript is only required on demand when the project contains .coffee files
        # in order to support pure javascript projects
        if extension is '.coffee'
          require('coffee-script/register')

        extension = require(filepath)

        Object.keys(extension).map (key) ->
          unless 'function' is typeof extension[key]
            throw new Error('export is not a function: ' + key + ' in :' + filepath)
          if object[key]?
            throw new Error('duplicate export: ' + key + ' in: ' + filepath + '. first was in: ' + object[key].$file)
          object[key] = extension[key]
          # add filename as metadata
          object[key].$file = filepath

      else if stat.isDirectory()
        filenames = fs.readdirSync(filepath)
        filenames.forEach (filename) ->
          loadFactories object, path.join(filepath, filename)

      return object

  hinoki.source = (arg) ->
    if 'function' is typeof arg
      arg
    else if Array.isArray arg
      coercedSources = arg.map hinoki.source
      (name) ->
        # try all sources in order
        index = -1
        length = sources.length
        while ++index < length
          result = coercedSources[index](name)
          if result?
            return result
        return null
    else if 'string' is typeof arg
      hinoki.source hinoki.requireSource arg
    else if 'object' is typeof arg
      (name) ->
        hinoki.source functionOrObject[name]
    else
      throw new Error 'argument must be a function, string, object or array of these'

################################################################################
# return the hinoki object from the factory

  return hinoki
)
