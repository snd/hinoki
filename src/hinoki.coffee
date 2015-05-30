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
      nameOrNamesOrFunction = arg3
    else
      lifetimes = [{}]
      nameOrNamesOrFunction = arg2

    cacheTarget = 0

    if 'function' is typeof nameOrNamesOrFunction
      names = hinoki.getNamesToInject(nameOrNamesOrFunction)
      paths = names.map(helfer.coerceToArray)
      return hinoki.getValuesAndCacheTarget(
        source,
        lifetimes,
        paths,
        cacheTarget
      ).promise.spread(nameOrNamesOrFunction)

    if Array.isArray nameOrNamesOrFunction
      names = helfer.coerceToArray(nameOrNamesOrFunction)
      paths = names.map(helfer.coerceToArray)
      return hinoki.getValuesAndCacheTarget(
        source,
        lifetimes,
        paths,
        cacheTarget
      ).promise

    path = helfer.coerceToArray(nameOrNamesOrFunction)
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
    name = path[0]
    # look if there already is a value for that name in one of the lifetimes
    lifetimeIndex = helfer.findIndexWhereProperty lifetimes, name
    unless lifetimeIndex is -1
      valueOrPromise = lifetimes[lifetimeIndex][name]
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

    # no cycle - yeah!

    # we have no value
    # look if there is a factory for that name in the source
    factory = source(name)
    unless factory?
      return new hinoki.PromiseAndCacheTarget(
        Promise.reject(new hinoki.NotFoundError(path))
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

    dependencyNames = hinoki.baseGetNamesToInject factory, true

    dependencyNamesIndex = -1
    dependencyNamesLength = dependencyNames.length
    dependencyPaths = []
    while ++dependencyNamesIndex < dependencyNamesLength
      dependencyName = dependencyNames[dependencyNamesIndex]
      newPath = path.slice()
      newPath.unshift dependencyName
      # is this name already in the path.
      # if so then it would introduce a circular dependency.
      if -1 isnt path.indexOf dependencyName
        return new hinoki.PromiseAndCacheTarget(
          Promise.reject(new hinoki.CircularDependencyError(newPath))
          cacheTarget
        )
      dependencyPaths.push newPath

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
    # lifetimes[nextCacheTarget][name] is undefined
    # because we checked that synchronously

    unless factory.__nocache
      lifetimes[nextCacheTarget][name] = factoryCallResultPromise

    returnPromise = factoryCallResultPromise
      .then (value) ->
        # cache
        unless factory.__nocache
          lifetimes[nextCacheTarget][name] = value
        return value
      .catch (error) ->
        # prevent errored promises from being reused
        # and allow further requests for the errored names to succeed.
        unless factory.__nocache
          delete lifetimes[nextCacheTarget][name]
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

      if 'function' is typeof f
        names = hinoki.getNamesToInject f
        dependencies = _.map names, (name) ->
          dependenciesObject[name]
        return hinoki.callFactoryFunction(newPath, f, dependencies)
      else if 'object' is typeof f
        # supports nesting
        return hinoki.callFactoryObjectArray(newPath, f, dependenciesObject)
      else
        throw new Error "f must be either array or object but is #{typeof f}"

    if Array.isArray factoryObject
      Promise.all(factoryObject).map(iterator)
    # object !
    else if 'object' is typeof factoryObject
      keys = Object.keys(factoryObject)
      length = keys.length
      i = -1
      result = {}
      while ++i < length
        key = keys[i]
        unless key is '__inject'
          result[key] = iterator(factoryObject[key], key)
      Promise.props result
    else
      throw new Error "factoryObject must be either array or object but is #{typeof factoryObject}"

  hinoki.callFactory = (path, factory, dependencyValues) ->
    if 'function' is typeof factory
      return hinoki.callFactoryFunction path, factory, dependencyValues
    else
      names = hinoki.getNamesToInject factory
      dependenciesObject = _.zipObject names, dependencyValues
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
    this.message = "neither value nor factory found for name `#{path[0]}` in path `#{hinoki.pathToString path}`"
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

################################################################################
# path

  hinoki.pathToString = (path) ->
    path.join ' <- '

################################################################################
# helper

  hinoki.getNamesToInject = (factory) ->
    hinoki.baseGetNamesToInject factory, false

  hinoki.baseGetNamesToInject = (factory, cache) ->
    if factory.__inject?
      return factory.__inject
    else if 'function' is typeof factory
      names = helfer.parseFunctionArguments factory
      if cache
        factory.__inject = names
      return names
    else if Array.isArray(factory) or ('object' is typeof factory)
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

  if fs? and pathModule?
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

        extension = require(filepath)

        Object.keys(extension).map (key) ->
          unless 'function' is typeof extension[key]
            throw new Error('export is not a function: ' + key + ' in :' + filepath)
          if object[key]?
            throw new Error('duplicate export: ' + key + ' in: ' + filepath + '. first was in: ' + object[key].__file)
          object[key] = extension[key]
          # add filename as metadata
          object[key].__file = filepath

      else if stat.isDirectory()
        filenames = fs.readdirSync(filepath)
        filenames.forEach (filename) ->
          hinoki.baseRequireSource pathModule.join(filepath, filename), object

      return object

  hinoki.source = (arg) ->
    if 'function' is typeof arg
      arg
    else if Array.isArray arg
      coercedSources = arg.map hinoki.source
      (name) ->
        # try all sources in order
        index = -1
        length = arg.length
        while ++index < length
          result = coercedSources[index](name)
          if result?
            return result
        return null
    else if 'string' is typeof arg
      hinoki.source hinoki.requireSource arg
    else if 'object' is typeof arg
      (name) ->
        arg[name]
    else
      throw new Error 'argument must be a function, string, object or array of these'

  hinoki.decorateSourceToAlsoLookupWithPrefix = (innerSource, prefix) ->
    (name) ->
      result = innerSource(name)
      if result?
        return result

      if 0 is name.indexOf(prefix)
        return null

      prefixedName = prefix + name
      # factory that resolves to the same value
      wrapperFactory = (wrapped) -> wrapped
      wrapperFactory.__inject = [prefixedName]
      return wrapperFactory

################################################################################
# return the hinoki object from the factory

  return hinoki
)
