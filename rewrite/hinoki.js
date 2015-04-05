// this file uses type annotations http://flowtype.org/
// every function in this file is optimizable by V8 crankshaft and will
// in fact get compiled and inlined after some warmup.
// lint
//
// here are some flowtype definitions that are used throughout this file:
//
// # FLOWTYPE
//
// type Factory = (...deps: any) => any

(
  function (root, factory) {
    if (typeof define === 'function' && define.amd) {
      // amd
      define(['bluebird', 'lodash'], factory);
    } else if (typeof exports !== 'undefined') {
      // commonjs
      module.exports = factory(
        require('bluebird'),
        require('lodash')
      );
    } else {
      // other
      root.hinoki = factory(root.Promise, root.lodash);
    }
  }
)(this, function (Promise, _) {
  'use strict';
  // TODO small, optimizable functions
  // TODO terminology
  // TODO make the output easily greppable
  // TODO name anonymous functions
  // TODO benchmark with real world containers
  // TODO merge benchmark, optimization test and unit/integration tests
  // TODO predictable random numbers for test data generation
  // TODO _.attempt instead of try catch block
  // TODO try not to do any unnecessary allocations
  // TODO many things can just be solved with executions instead
  // TODO how to error handling
  // TODO make one huge integration benchmark file and ensure that all are optimized
  // TODO only if a factory returns a promise does async even happen
  // TODO check that all/most are inlined as well !!!
  // TODO a function that returns optimization state for each hinoki function
  // TODO preallocate arrays
  // TODO remove lodash dependency
  // TODO remove Promise dependency

  // this is the factory. make an exception and allow many statements:
  // jshint maxstatements: false

  // boolean
  function isObjectLike(
    // any
    value
  ) {
    return (value && typeof value == 'object');
  }

  // boolean
  function isPromise(
    // any
    value
  ) {
    // inlined isObjectLike
    return (isObjectLike(value) && typeof value.then == 'function');
  }

  var regexFunctionArguments = /\(([^\s,]+)\)/g;

  // Array<string>
  function parseFunctionArguments(
    // (...args: any) => any
    func
  ) {
    return Function.prototype.toString.call(func).match(regexFunctionArguments) || [];
  }

  // Array<string>
  function getFactoryDependencies(
    // (...args: any) => any
    factory
  ) {
    if (_.isArray(factory.$inject)) return factory.$inject;
    // inlined parseFunctionArguments
    return parseFunctionArguments(factory);
  }

  // TODO rename to make side effect more clear
  // Array<string>
  function getAndCacheFactoryDependencies(
    // (...args: any) => any
    factory
  ) {
    if (_.isArray(factory.$inject)) return factory.$inject;
    // inlined parseFunctionArguments
    var names = parseFunctionArguments(factory);
    factory.$inject = names;
    return names;
  }

  // boolean
  function arrayOfStringsHasDuplicates(
    // Array<string>
    array
  ) {
    var index = -1;
    var length = array.length;
    var seen = {};
    // TODO use a set cache here
    while (++index < length) {
      var value = array[index];
      // inlined _.has
      if (_.has(seen, value)) {
        return true;
      }
      seen[value] = true;
    }
    return false;
  }

  // ValueResult
  function ValueResult(
    // any
    value
  ) {
    this.value = value;
  }

  // FactoryResult
  function FactoryResult(
    // string
    name,
    // (...args: any) => any
    factory
  ) {
    this.name = name;
    this.factory = factory;
    this.nocache = false;
  }

  // type Resolver =
  // (name: string, container: Container) => ValueResult | FactoryResult

  // ? ValueResult | FactoryResult
  function defaultResolver(
    // string
    name,
    // Container
    container
  ) {
    // inlined isObjectLike
    if (!isObjectLike(container.values)) return;
    var value = container.values[name];
    // inlined _.isUndefined and ValueResult
    if (!_.isUndefined(value)) return new ValueResult(value);

    // inlined isObjectLike
    if (!isObjectLike(container.factories)) return;
    var factory = container.factories[name];
    // inlined _.isFunction
    if (!_.isFunction(factory)) return;

    // inlined getDependenciesCached and FactoryResult
    getDependenciesCached(factory);
    return new FactoryResult(name, factory);
  }

  // TODO baseFunctions

  // TODO is this even needed?
  // just make the public api stricter
  //
  // Array<T>
  function coerceIntoArray(
    value // ? Array<T> | T
  ) {
    if (_.isArray(value)) {
      return value;
    }
    if (!value) {
      return [];
    }
    return [value];
  }

  function Container(
    // { [name: string]: Factory }
    factories,
    // Object<any>
    cache
  ) {
    this.factories = factories || {};
    this.constants = constants || {};
    this.cache = cache || {};
    // stores promises
    this.unresolved = {};
    this.resolvers = resolvers || [];
  }

  // 

  Container.prototype.addResolver = function(resolver) {
    this.resolvers.push(resolver);
  }

  // ? ValueResult | FactoryResult
  function baseResolveNameInContainer(
    // string
    name,
    // Container
    container,
    // Array<Resolver>
    resolvers,
    // int
    index
  ) {
    if (resolvers.length <= index) {
      return defaultResolver(name, container);
    }

    resolvers[index](
      name,
      container,
      function callInnerResolverFromOuterResolver(nameFromOuter) {
        return baseResolveNameInContainer(
          nameFromOuter,
          container,
          resolvers,
          index + 1
        );
      }
    );
  }

  // ? ValueResult | FactoryResult
  function resolveNameInContainer(
    // string
    name,
    // Container
    container
  ) {
    return baseResolveNameInContainer(
      name,
      container,
      container.resolvers || [],
      0
    );
  }

  // TODO you probably dont need this
  // resolve into each container after the other

  // ? ValueResult | FactoryResult
  // function resolveInContainers(
  //   // Array<Container>
  //   containers,
  //   // string
  //   name
  // ) {
  //   return _.find(
  //     containers,
  //     function resolveInContainersFindPredicate(container) {
  //       return resolveNameInContainer(name, container);
  //     }
  //   );
  // }

  // TODO this is probably not even needed
  // type Result = any | Error | Promise<any, Error>
//   function callFactory(
//     // Container
//     container
//   ) {
//
//   }

  // TODO ???
  // Promise<any, Error>
//   function getPromise(
//
//   ) {
//
//   }

  // Array<string>
  function nameToPath(
    // string
    name
  ) {
    return [name];
  }

  // Array<Array<string>>
  function namesToPaths(
    // Array<string>
    names
  ) {
    return _.map(names, nameToPath);
  }

  // polymorphic (difficult to optimize for V8) but flexible API
  // does very little and delegates heavy lifting
  // to monomorphic optimizable functions

  // Result
  function get(
    // Container | Array<Container>
    oneOrManyContainers,
    // string | Array<string>
    oneOrManyNames
  ) {
    var manyNames = _.isArray(oneOrManyNames);
    // most common case
    if (_.isArray(oneOrManyContainers)) {
      if (manyNames) {
        return baseTryContainers(
          namesToPaths(oneOrManyNames),
          oneOrManyContainers
        );
      } else {
        return baseTryContainers(
          nameToPath(oneOrManyNames),
          oneOrManyContainers
        );
      }
    } else {
      if (manyNames) {
        return baseGetMany(
          namesToPaths(oneOrManyNames),
          [oneOrManyContainers],
          0
        );
      } else {
        return baseGetOne(
          nameToPath(oneOrManyNames),
          [oneOrManyContainers],
          0
        );
      }
    }
  }

  // look up in any of the containers
  // any | Error | ResolvedPromise<any> | RejectedPromise<Error>
  function baseTryContainers(
    // Path
    path,
    // Array<Container>
    containers
  ) {
    var index = -1;
    var length = containers.length;
    while (++index < length) {
      var result = baseGetOne(path, containers, index);
      if (result) {
        return result;
      }
    }
  }

  if (set) {
    function createCache(values) {

    }

    function isCached(value) {

    }
  }

  // TODO use a set if possible

  // ? string
  function wouldIntroduceCycle(
    // Array<string>
    path,
    // Array<string>
    names
  ) {
    // very fast cycle detection O(path.length + names.length)
    var length = names.length;
    if (length === 0 || path.length === 0) return;

    var cache = createCache(path);
    var index = -1;
    while (++index < length) {
      var name = names[index];
      if (isCached(cache, name)) return name;
    }
  }

  // unoptimizable because it uses try/catch
  function attempt(
    func,
    args
  ) {
    try {
      return func.apply(undefined, args);
    } catch(e) {
      return _.isError(e) ? e : new Error(e);
    }
  }

  // equialvalent to and faster than:
  // names.map(function(name) {
  //   var newPath = path.slice(0);
  //   path.unshift(name);
  //   return newPath;
  // })

  // Array<Array<string>>
  function getNextPaths(
      // Array<string>
      path,
      // Array<string>
      names
  ) {
      var pathLength = path.length;
      var namesLength = names.length;
      var nameIndex = -1;
      var nextPaths = Array(namesLength);
      while (++nameIndex < namesLength) {
        var nextPath = Array(pathLength + 1);
        nextPath[0] = names[nameIndex];

        var pathIndex = -1;
        while (++pathIndex < pathLength) {
          nextPath[pathIndex + 1] = path[pathIndex]
        }
      }
      return nextPaths;
  }

  function baseCallFactory(
    factory,
    // Array<any>
    dependencies
  ) {
    var resultOrError = attempt(factory, dependencies);

    if (_.isError(resultOrError)) {
      // TODO first make a error in resolution error from it
      return resultOrError;
    }

    // TODO promise rejected error ???

    return resultOrError;
  }

  // any
  function baseHandleFactory(
    // Array<string>
    path,
    // (...deps: any) => any
    factory,
    // Container
    containers,
    // int
    containerIndex
  ) {
    // TODO get dependencies

    // TODO this function is getting WAY too large: DELEGATE !!!

    var dependencyNames = getDependenciesCached(factory);

    // no dependencies
    if (dependencyNames.length === 0) {
      return callFactory(factory, []);
      // TODO call shared handleFactoryResult
      return;
    }

    var nameThatWouldIntroduceCycle = wouldIntroduceCycle(path, dependencyNames);
    if (nameThatWouldIntroduceCycle) {
      // TODO real cycle error
      return new Error('cycle');
    }

    var dependencyPaths = getNextPaths(path, dependencyNames);

    if (dependencyNames.length === 1) {
      var dependencyResult = baseGetOne(dependencyPaths[1], containers, containerIndex);
    }
      var dependencyResult = baseGetMany(dependencyPaths, containers, containerIndex);

    // TODO handle failure in dependencyResult

    if (isPromise(dependencyResult)) {
      return dependencyResult.then(function(dependencies) {
        return callFactory(factory, dependencies);
      });
    } else {
      return callFactory(factory, dependencyResult);
    }
  }

  // any | Error | ResolvedPromise<any> | RejectedPromise<Error>
  function baseGetOne(
    // Path
    path,
    // Array<Container>
    containers,
    // int
    containerIndex
  ) {
    // this is the only function that actually does anything significant

    var resultOrError = _.attempt(resolveName, path[0], containers[containerIndex]);
    if (_.isError(resultOrError)) {
      // TODO first make a error in resolution error from it
      return resultOrError;
    }

    if (!resultOrError) {
      // TODO unresolvable error
      // we might also just return null in that case
    }

    // TODO value result doesnt need a name property actually
    if (!_.isUndefined(resultOrError.value)) {
      return resultOrError.value;
    }

    if (!_.isFunction(resultOrError.factory)) {

    }

    if (!_.isString(resultOrError.name)) {

    }

    // TODO cache instruction ???

    // TODO do we really need container here ? yes, for caching
    return baseHandleFactory(result.name, result.factory, container);
  }

  // Array<any> | Error | ResolvedPromise<Array<any>> | RejectedPromise<Error>
  function baseGetMany(
    // Array<Array<string>>
    paths,
    // Array<Container>
    containers
    // int
    containerIndex
  ) {
    var length = paths.length;
    var isAnyResultAPromise = false
    var results = Array(paths.length)
    var index = -1;
    while (++index < length) {
      var result = baseGetOne(path, containers, containerIndex));
      // TODO put this into baseGetOne
      if (!result) {
        // TODO unresolvable error
      }
      if (_.isError(result)) {
        return result;
      }
      if (isPromise(result) && !isAnyResultAPromise) {
        isAnyResultAPromise = true;
      }
      // TODO promise merge
      results[index] = result;
    }
    // Promise.all(results);
    if (!isAnyResultAPromise) {
      return results;
    } else
      return Promise.all(results);
    }
  }

  // TODO check cycle by checking for existence before building paths

  // export

  var hinoki = {};

  hinoki.isObjectLike = isObjectLike;
  hinoki.isPromise = isPromise;
  hinoki.parseFunctionArguments = parseFunctionArguments;
  hinoki.getDependencies = getDependencies;
  hinoki.getAndCacheDependencies = getAndCacheDependencies;
  hinoki.arrayOfStringsHasDuplicates = arrayOfStringsHasDuplicates;
  hinoki.resolveNameInContainer = resolveNameInContainer;
  hinoki.baseResolveNameInContainer = baseResolveNameInContainer;
  hinoki.defaultResolver = defaultResolver;
  hinoki.coerceIntoArray = coerceIntoArray;
  hinoki.ValueResult = ValueResult;
  hinoki.FactoryResult = FactoryResult;
  hinoki.Container = Container;
  hinoki.get = get;

  // reexport from lodash

  hinoki.isError = _.isError;

  return hinoki;
});
