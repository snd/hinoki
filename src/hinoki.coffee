((root, factory) ->
  # amd
  if ('function' is typeof define) and define.amd?
    define(['bluebird', 'helfer', 'lodash'], factory)
  # nodejs
  else if exports?
    module.exports = factory(
      require('bluebird')
      require('lodash')
      require('helfer')
      require('fs')
      require('path')
    )
  # other
  else
    root.hinoki = factory(root.Promise, root.helfer, root.lodash)
)(this, (Promise, _, helfer, fs, pathModule) ->

################################################################################
# get

  # polymorphic
  hinoki = (arg1, arg2, arg3) ->
    source = hinoki.source arg1

    if arg3?
      lifetimes = helfer.coerceToArray arg2
      keyOrKeysOrFunction = arg3
    else
      lifetimes = [{}]
      keyOrKeysOrFunction = arg2

    cacheTarget = 0

    if 'function' is typeof keyOrKeysOrFunction
      keys = hinoki.getKeysToInject(keyOrKeysOrFunction)
      paths = _.map keys, helfer.coerceToArray
      return hinoki.getValuesAndCacheTarget(
        source,
        lifetimes,
        paths,
        cacheTarget
      ).promise.spread(keyOrKeysOrFunction)

    if Array.isArray keyOrKeysOrFunction
      keys = helfer.coerceToArray(keyOrKeysOrFunction)
      paths = _.map keys, helfer.coerceToArray
      return hinoki.getValuesAndCacheTarget(
        source,
        lifetimes,
        paths,
        cacheTarget
      ).promise

    path = helfer.coerceToArray(keyOrKeysOrFunction)
    return hinoki.getValueAndCacheTarget(
      source,
      lifetimes,
      path,
      cacheTarget
    ).promise

  # monomorphic
  hinoki.PromiseAndCacheTarget = (promise, cacheTarget) ->
    this.promise = promise
    this.cacheTarget = cacheTarget
    return this

  # monomorphic
  hinoki.getValuesAndCacheTarget = (source, lifetimes, paths, cacheTarget) ->
    # result.cacheTarget is determined synchronously
    nextCacheTarget = cacheTarget
    # result.promise is fulfilled asynchronously
    promise = Promise.all(_.map(paths, (path) ->
      result = hinoki.getValueAndCacheTarget(
        source
        lifetimes
        path
        cacheTarget
      )
      nextCacheTarget = Math.max(nextCacheTarget, result.cacheTarget)
      return result.promise
    ))
    return new hinoki.PromiseAndCacheTarget promise, nextCacheTarget

  # monomorphic
  hinoki.getValueAndCacheTarget = (source, lifetimes, path, cacheTarget) ->
    key = path[0]
    # look if there already is a value for that key in one of the lifetimes
    lifetimeIndex = helfer.findIndexWhereProperty lifetimes, key
    unless lifetimeIndex is -1
      valueOrPromise = lifetimes[lifetimeIndex][key]
      promise =
        if helfer.isThenable valueOrPromise
          # if the value is already being constructed
          # wait for that instead of starting a second construction.
          hinoki.debug? {
            event: 'lifetimeHasPromise'
            path: path
            promise: valueOrPromise
            lifetime: lifetimes[lifetimeIndex]
            lifetimeIndex: lifetimeIndex
          }
          valueOrPromise
        else
          hinoki.debug? {
            event: 'lifetimeHasValue'
            path: path
            value: valueOrPromise
            lifetime: lifetimes[lifetimeIndex]
            lifetimeIndex: lifetimeIndex
          }
          Promise.resolve valueOrPromise
      return new hinoki.PromiseAndCacheTarget promise, lifetimeIndex

    # we have no value
    # look if there is a factory for that key in the source
    factory = source(key)
    unless factory?
      return new hinoki.PromiseAndCacheTarget(
        Promise.reject(new hinoki.NotFoundError(path))
        cacheTarget
      )

    unless hinoki.isFactory factory
      return new hinoki.PromiseAndCacheTarget(
        Promise.reject new hinoki.BadFactoryError path, factory
        cacheTarget
      )

    hinoki.debug? {
      event: 'sourceReturnedFactory'
      path: path
      factory: factory
    }

    # we've got a factory.
    # lets make a value

    # first lets resolve the dependencies of the factory

    dependencyKeys = hinoki.baseGetKeysToInject factory, true

    dependencyKeysIndex = -1
    dependencyKeysLength = dependencyKeys.length
    dependencyPaths = []
    while ++dependencyKeysIndex < dependencyKeysLength
      dependencyKey = dependencyKeys[dependencyKeysIndex]
      newPath = path.slice()
      newPath.unshift dependencyKey
      # is this key already in the path?
      # if so then it would introduce a circular dependency.
      if -1 isnt path.indexOf dependencyKey
        return new hinoki.PromiseAndCacheTarget(
          Promise.reject(new hinoki.CircularDependencyError(newPath))
          cacheTarget
        )
      dependencyPaths.push newPath

    # no cycle - yeah!

    # this code is reached synchronously from the start of the function call
    # without interleaving.

    if dependencyPaths.length isnt 0
      result = hinoki.getValuesAndCacheTarget(
        source,
        lifetimes,
        dependencyPaths,
        cacheTarget
      )
      dependenciesPromise = result.promise
      nextCacheTarget = result.cacheTarget
    else
      dependenciesPromise = Promise.resolve([])
      nextCacheTarget = cacheTarget

    factoryCallResultPromise = dependenciesPromise.then (dependencyValues) ->
      # the dependencies are ready!
      # we can finally call the factory!
      return hinoki.callFactory(path, factory, dependencyValues)

    # cache the promise:
    # this code is reached synchronously from the start of the function call
    # without interleaving.
    # its important that the factoryCallResultPromise is added
    # to lifetimes[maxCacheTarget] synchronously
    # because as soon as control is given back to the scheduler
    # another process might request the value as well.
    # this way that process just reuses the factoryCallResultPromise
    # instead of building it all over again.
    # invariant:
    # if we reach this line we are guaranteed that:
    # lifetimes[nextCacheTarget][key] is undefined
    # because we checked that synchronously

    unless factory.__nocache
      lifetimes[nextCacheTarget][key] = factoryCallResultPromise

    returnPromise = factoryCallResultPromise
      .then (value) ->
        # cache
        unless factory.__nocache
          lifetimes[nextCacheTarget][key] = value
        return value
      .catch (error) ->
        # prevent errored promises from being reused
        # and allow further requests for the errored keys to succeed.
        unless factory.__nocache
          delete lifetimes[nextCacheTarget][key]
        return Promise.reject error

    return new hinoki.PromiseAndCacheTarget(returnPromise, nextCacheTarget)

  # try catch prevents functions from being optimized.
  # wrapping it into a function keeps the unoptimized part small.
  hinoki.tryCatch = (fun, args) ->
    try
      return fun.apply null, args
    catch error
      if helfer.isError error
        return error
      else
        return new Error error.toString()

  # returns a promise
  hinoki.callFactoryFunction = (path, factoryFunction, args) ->
    result = hinoki.tryCatch(factoryFunction, args)
    if helfer.isUndefined result
      # note that a null value is allowed!
      return Promise.reject new hinoki.FactoryReturnedUndefinedError path, factoryFunction
    if helfer.isError(result)
      return Promise.reject new hinoki.ErrorInFactory path, factoryFunction, result
    if helfer.isThenable result
      hinoki.debug? {
        event: 'factoryReturnedPromise'
        path: path
        promise: result
        factory: factoryFunction
      }
      return result
        .then (value) ->
          hinoki.debug? {
            event: 'promiseResolved'
            path: path
            value: value
            factory: factoryFunction
          }
          return value
        .catch (rejection) ->
          Promise.reject new hinoki.PromiseRejectedError path, factoryFunction, rejection
    hinoki.debug? {
      event: 'factoryReturnedValue'
      path: path
      value: result
      factory: factoryFunction
    }
    return Promise.resolve result

  hinoki.callFactoryObjectArray = (path, factoryObject, dependenciesObject) ->
    iterator = (f, key) ->
      newPath = path.slice()
      newPath[0] += '[' + key + ']'

      unless hinoki.isFactory f
        return Promise.reject new hinoki.BadFactoryError newPath, f

      if 'function' is typeof f
        dependencyKeys = hinoki.getKeysToInject f
        dependencies = _.map dependencyKeys, (dependencyKey) ->
          dependenciesObject[dependencyKey]
        return hinoki.callFactoryFunction(newPath, f, dependencies)
      else if 'object' is typeof f
        # supports nesting
        return hinoki.callFactoryObjectArray(newPath, f, dependenciesObject)

    if Array.isArray factoryObject
      Promise.all(factoryObject).map(iterator)
    else if 'object' is typeof factoryObject
      keys = Object.keys(factoryObject)
      length = keys.length
      i = -1
      result = {}
      while ++i < length
        key = keys[i]
        unless key is '__inject'
          result[key] = iterator(factoryObject[key], key)
      return Promise.props result

  hinoki.callFactory = (path, factory, dependencyValues) ->
    if 'function' is typeof factory
      return hinoki.callFactoryFunction path, factory, dependencyValues
    else
      dependencyKeys = hinoki.getKeysToInject factory
      dependenciesObject = _.zipObject dependencyKeys, dependencyValues
      return hinoki.callFactoryObjectArray path, factory, dependenciesObject

################################################################################
# errors

  # constructors for errors which are catchable with bluebirds `catch`

  # the base error for all other hinoki errors
  # not to be instantiated directly
  hinoki.BaseError = ->
  helfer.inherits hinoki.BaseError, Error

  hinoki.NotFoundError = (path) ->
    this.name = 'NotFoundError'
    this.message = "neither value nor factory found for `#{path[0]}` in path `#{hinoki.pathToString path}`"
    if Error.captureStackTrace?
      # second argument excludes the constructor from inclusion in the stack trace
      Error.captureStackTrace(this, this.constructor)
    this.path = path
    return
  helfer.inherits hinoki.NotFoundError, hinoki.BaseError

  hinoki.CircularDependencyError = (path) ->
    this.name = 'CircularDependencyError'
    this.message = "circular dependency `#{hinoki.pathToString path}`"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)
    this.path = path
    return
  helfer.inherits hinoki.CircularDependencyError, hinoki.BaseError

  hinoki.ErrorInFactory = (path, factory, error) ->
    this.name = 'ErrorInFactory'
    this.message = "error in factory for `#{path[0]}`. original error `#{error.toString()}`"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)
    this.path = path
    this.factory = factory
    this.error = error
    return
  helfer.inherits hinoki.ErrorInFactory, hinoki.BaseError

  hinoki.FactoryReturnedUndefinedError = (path, factory) ->
    this.name = 'FactoryReturnedUndefinedError'
    this.message = "factory for `#{path[0]}` returned undefined"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)
    this.path = path
    this.factory = factory
    return
  helfer.inherits hinoki.FactoryReturnedUndefinedError, hinoki.BaseError

  hinoki.PromiseRejectedError = (path, factory, error) ->
    this.name = 'PromiseRejectedError'
    this.message = "promise returned from factory for `#{path[0]}` was rejected. original error `#{error.toString()}`"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)
    this.path = path
    this.factory = factory
    this.error = error
    return
  helfer.inherits hinoki.PromiseRejectedError, hinoki.BaseError

  hinoki.BadFactoryError = (path, factory) ->
    this.name = 'BadFactoryError'
    this.message = "factory for `#{path[0]}` has to be a function, object of factories or array of factories but is `#{typeof factory}`"
    if Error.captureStackTrace?
      Error.captureStackTrace(this, this.constructor)
    this.path = path
    this.factory = factory
    return
  helfer.inherits hinoki.BadFactoryError, hinoki.BaseError

################################################################################
# helper

  hinoki.pathToString = (path) ->
    path.join ' <- '

  hinoki.getKeysToInject = (factory) ->
    hinoki.baseGetKeysToInject factory, false

  hinoki.baseGetKeysToInject = (factory, cache) ->
    if factory.__inject?
      return factory.__inject

    type = typeof factory
    if ('object' is type) or ('function' is type)
      if ('function' is type)
        keys = helfer.parseFunctionArguments factory
      else
        keysSet = {}
        _.forEach factory, (subFactory) ->
          subKeys = hinoki.baseGetKeysToInject(subFactory, cache)
          _.forEach subKeys, (subKey) ->
            keysSet[subKey] = true
        keys = Object.keys(keysSet)
      if cache
        factory.__inject = keys
      return keys

    return []

  hinoki.isFactory = (value) ->
    type = typeof value
    (type is 'function') or Array.isArray(value) or (type is 'object')

################################################################################
# functions for working with sources

  # returns an object containing all the exported properties
  # of all `*.js` and `*.coffee` files in `filepath`.
  # if `filepath` is a directory recurse into every file and subdirectory.

  if fs? and pathModule?
    # TODO better name
    hinoki.requireSource = (filepath) ->
      unless 'string' is typeof filepath
        throw new Error 'argument must be a string'
      hinoki.baseRequireSource filepath, {}

    # TODO call this something like fromExports
    hinoki.baseRequireSource = (filepath, object) ->
      stat = fs.statSync(filepath)
      if stat.isFile()
        extension = pathModule.extname(filepath)

        if extension isnt '.js' and extension isnt '.coffee'
          return

        # coffeescript is only required on demand when the project contains .coffee files
        # in order to support pure javascript projects
        if extension is '.coffee'
          require('coffee-script/register')

        exports = require(filepath)

        Object.keys(exports).map (key) ->
          unless hinoki.isFactory exports[key]
            throw new Error('export is not a factory: ' + key + ' in :' + filepath)
          if object[key]?
            throw new Error('duplicate export: ' + key + ' in: ' + filepath + '. first was in: ' + object[key].__file)
          object[key] = exports[key]
          # add filename as metadata
          object[key].__file = filepath

      else if stat.isDirectory()
        filenames = fs.readdirSync(filepath)
        filenames.forEach (filename) ->
          hinoki.baseRequireSource pathModule.join(filepath, filename), object

      return object

  hinoki.source = (arg) ->
    if 'function' is typeof arg
      return arg

    if Array.isArray arg
      coercedSources = _.map arg, hinoki.source
      source = (key) ->
        # try all sources in order
        index = -1
        length = arg.length
        while ++index < length
          result = coercedSources[index](key)
          if result?
            return result
        return null
      source.keys = ->
        keys = []
        _.each coercedSources, (source) ->
          if source.keys?
            keys = keys.concat(source.keys())
        return keys
      return source

    if 'string' is typeof arg
      return hinoki.source hinoki.requireSource arg

    if 'object' is typeof arg
      source = (key) ->
        arg[key]
      source.keys = ->
        Object.keys(arg)
      return source

    throw new Error 'argument must be a function, string, object or array of these'

  hinoki.decorateSourceToAlsoLookupWithPrefix = (innerSource, prefix) ->
    source = (key) ->
      result = innerSource(key)
      if result?
        return result

      if 0 is key.indexOf(prefix)
        return null

      # factory that resolves to the same value
      wrapperFactory = (wrapped) -> wrapped
      wrapperFactory.__inject = [prefix + key]
      return wrapperFactory
    if innerSource.keys?
      source.keys = innerSource.keys
    return source

################################################################################
# return the hinoki object from the factory

  return hinoki
)
