# hinoki

[![NPM version](https://badge.fury.io/js/hinoki.svg)](http://badge.fury.io/js/hinoki)
[![Build Status](https://travis-ci.org/snd/hinoki.svg?branch=master)](https://travis-ci.org/snd/hinoki/branches)
[![Dependencies](https://david-dm.org/snd/hinoki.svg)](https://david-dm.org/snd/hinoki)

>  magical inversion of control for nodejs and the browser

hinoki is a powerful and flexible asynchronous dependency injection system
designed to manage complexity in large applications

hinoki is inspired by [prismatic's graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife) and [angular's dependency injection](http://docs.angularjs.org/guide/di).

*hinoki takes its name from the hinoki cypress, a tree that only grows in japan and is the preferred wood for building palaces, temples and shrines...*

### hinoki features

in a nutshell

- [large test suite](test)
- [just ~500 lines of code](src/hinoki.coffee)
- battle-tested in production
- [a functional data-driven approach with localized mutable state](#containers)
- a simple carefully-designed (underlying) model
flexible core
a simple, carefully-designed and flexible core with many useful qualities

Use multiple Containers with different lifetimes that reference each Other

containers with lower lifetimes can depend on containers with higher lifetimes

A is active during a request but depends on some Things in b which lives through the entire process

containers can depend on other containers
granular control over
that allows functionality/features to emerge around it
that enables a lot of emerging functionality to be build with it.
- decomplected
- [asynchronous dependencies through promises](#asynchronous)
- works in [node.js](#nodejs-setup) and in the [browser](#browser-setup)
- [powerful error handling](#error-handling)
- [powerful logging & debugging for every step of the dependency injection process](#logging-debugging)
- [the ability to use multiple containers opens up interesting possibilities](#multiple-containers)
- [ability to intercept](#resolvers)

#### ~~ HINOKI IS A WORK IN PROGRESS ~~

it is used in production and growing with the challenges encountered there

hinoki will always stay true to its core principles.

- a functional data-driven rather than object oriented approach
- small elegant codebase
- simple, well-thought-out carefully-designed

if you would like to

if you use hinoki i am very happy to hear from you.

### index

- [why hinoki?](#why-hinoki)
- [node.js setup](#nodejs-setup)
- [browser setup](#browser-setup)
- [getting started](#getting-started)
- [in depth](#in-depth)
  - [containers](#containers)
  - [asynchronous dependencies](#asynchronous-dependencies)
  - [parsing dependencies from function arguments](#parsing-dependencies-from-function-arguments)
  - [dependencies of factory functions](#dependencies-of-factory-functions)
  - [multiple containers](#multiple-containers)
  - [logging & debugging](#logging-debugging)
  - [error handling](#error-handling)
  - [resolvers](#resolvers)
- [reference](#reference)
  - [API](#api)
    - [`hinoki.get`](#hinokiget)
  - [errors](#errors)
- [changelog](#changelog)
- [license](#license-mit)

## why hinoki?

system of such pieces where some depend on others

software systems are composed of many pieces that depend on
each other in various ways.

libraries, functions for accessing the database

dependency injection is a 

building blocks

simplifies getting data to where its needed

programming against an interface.

wire up closures on the fly

a lot more testable

hinoki allows you to declare the ways in which those pieces
depend on each other and can then resolve the dependencies automatically.

mock

self contained units

separation of concerns

very testable

[see the example app](example-app) [(entry point is main.js)](example-app/main.js)

## node.js setup

```
npm install hinoki
```

```javascript
var hinoki = require('hinoki');
```

## browser setup

your markup should look something like the following

```html
<html>
  <body>
    <!-- content... -->

    <!-- hinoki requires bluebird -->
    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/bluebird/1.2.2/bluebird.js"></script>
    <!-- take src/hinoki.js from this repository and include it -->
    <script type="text/javascript" src="hinoki.js"></script>
    <!-- your script can now access hinoki through the global var `hinoki` -->
    <script type="text/javascript" src="example.js"></script>
  </body>
</html>
```

[hinoki.js](src/hinoki.js) makes the global variable `hinoki` available

*its best to fetch bluebird with [bower](http://bower.io/),
[hinoki with npm](https://www.npmjs.org/package/hinoki) and then use
a build system like [gulp](http://gulpjs.com/) to bring everything together*

## getting started

in the world of hinoki a **NAME** uniquely identifies a part of a system.
a **NAME** can have a **VALUE**:
it could be a function, a piece of data, an object, a module, a library...

```javascript
var values = {
  xs: [1, 2, 3, 6]
};
```

a **NAME** can depend on other **NAMES**, its dependencies.

a **FACTORY** for a **NAME** is a function that takes
the **VALUES** of the **NAME's** dependencies
and returns the **VALUE** of the **NAME**:

```javascript
var factories = {
  count: function(xs) {
    return xs.length;
  },
  mean: function(xs, count) {
    var reducer = function(acc, x) {
      return acc + x;
    };
    return xs.reduce(reducer, 0) / count;
  },
  meanOfSquares: function(xs, count) {
    var reducer = function(acc, x) {
      return acc + x * x;
    };
    return xs.reduce(reducer, 0) / count;
  },
  variance: function(mean, meanOfSquares) {
    return meanOfSquares - mean * mean;
  }
};
```

a **CONTAINER** manages the **FACTORIES** and **VALUES** for a set of **NAMES**:

```javascript
var container = {
  factories: factories,
  values: values
};
```

[**CONTAINERS** are just a plain old javascript objects](#containers)

a **CONTAINER** can be asked for the **VALUE** of a **NAME**:

```javascript
hinoki.get(container, 'mean').then(function(mean) {
  console.log(mean);  // -> 3
});
```

hinoki always returns a promise: to normalize synchronous and asynchronous
dependencies and to simplify error handling.

asking for an uncached **NAME** will ask for its dependencies (and their dependencies...),
call its **FACTORY** to get the **VALUE** and cache the new **VALUES** in
the **CONTAINER**:

```javascript
console.log(container.values);
// ->
// { xs: [ 1, 2, 3, 6 ],
//   count: 4,
//   mean: 3 }
```

asking for a cached **NAME** again will return the cached **VALUE**.

```javascript
hinoki.get(container, 'count').then(function(count) {
  console.log(mean);  // -> 3
});
```

```javascript
hinoki.get(container, 'variance').then(function(variance) {
  console.log(variance);  // -> 3.5

  console.log(container.values);
  // ->
  // { xs: [ 1, 2, 3, 6 ],
  //   count: 4,
  //   mean: 3,
  //   meanOfSquares: 12.5,
  //   variance: 3.5 }
});

```

[see the whole example again](example/computation.js)

## in depth

### containers

hinoki itself uses no global or module-level mutable state.

its side effects are localized in containers:
hinoki adds values to containers.
containers are just data (plain old javascript objects).
inspect and manipulate them easily using standard javascript.

scope

lifetime

think about containers as tuples of **VALUES** and **FACTORIES**
that belong together in a specific combination.

feel free to mix and match.

feel free to tear them apart.

it's often useful for multiple **CONTAINERS** to use the same **FACTORIES**
but different **VALUES**

```javascript
var otherValues = {
  xs: [2, 3, 4, 5]
};

var otherContainer = {
  factories: factories,
  values: otherValues
};

hinoki.get(otherContainer, 'mean').then(function(mean) {
  console.log(mean);  // -> 3.5
  console.log(otherContainer.values);
  // ->
  // { xs: [ 2, 3, 4, 5 ],
  //   count: 4,
  //   mean: 3.5 }
  });
```

a **CONTAINER** owns **VALUES** and controls their scope and lifetime.

just use a new **CONTAINER** whenever you need a fresh scope.

### asynchronous dependencies

if a factory returns a *thenable* (for example a [bluebird](https://github.com/petkaantonov/bluebird)
, [q](https://github.com/kriskowal/q) or [when](https://github.com/cujojs/when) promise)
hinoki will resolve it automatically.

if the promise returned by a factory is rejected
then the promise returned by hinoki is rejected
with a [hinoki.PromiseRejectedError](#promiserejectederror).

with asynchronous dependencies hinoki makes it easy to
structure asynchronous computation.

[see example](example/async-bluebird.js)

### parsing dependencies from function arguments

```javascript
var factory = function(variance, mean) {
  /* ... */
};

var dependencyNames = hinoki.getFunctionArguments(factory);
// -> ['variance', 'mean']

hinoki.get(container, dependencyNames).spread(factory);
```

asks container for `variance` and `mean` and calls `factory` with them.

### dependencies of factory functions

if a factory function has the `$inject` property containing an
array of dependency names then hinoki will ask for values of those names
and inject them into the factory.

otherwise hinoki will parse the dependency names from the factory
function arguments and cache them in the `$inject` property of the factory
function:

```javascript
var factories = {
  a: function() { return 'a'; },
  b: function() { return 'b'; },
  c: function() { return 'c'; },
  d: function() { return 'd'; },
  // this should depend on ['a', 'c'], we override this below
  ac: function(a, b) { return a + b; },
  acd: function(ac, d) { return ac + d; }
};

factories.ac.$inject = ['a', 'c'];

var container = {
  factories: factories
};

hinoki.get(container, 'acd', console.log).then(function(acd) {
  console.log(acd);  // -> 'acd'
  // dependency names have been cached
  console.log(factories.a.$inject); // -> []
  console.log(factories.acd.$inject); // -> ['ac', 'd']
});
```

[source](example/dollar-inject.js)

### multiple containers

hinoki supports multiple containers.

containers are asked in order from first to last.

values are added to the container that resolved the factory.

factories can depend on dependencies in succeeding containers.

[see example](example/request.js) ...you get the idea ;-)

this opens new possibilities for web development - demo application coming soon!

### scope


### logging & debugging

pass in a callback as the third argument to `hinoki.get`
and it will be called on various steps during the dependency injection process:

```javascript
hinoki.get(container, 'variance', console.log)
  .then(function(variance) {
    /* ... */
  });
```

the callback will be called with an event object which has the following properties:

- `event` = one of `valueFound`, `factoryFound`, `valueUnderConstruction`, `valueCreated`,
`promiseCreated`, `promiseResolved`
- `name` = **NAME** of the dependency that caused the event
- `path` = full dependency path
(call `path.toString() -> 'a <- b <- c'` or `path.segments() -> ['a', 'b', 'c']`)
- `container` = the **CONTAINER** on which the event occured
- `value` = the value (just for `valueFound`, `valueCreated` and `promiseResolved`)
- `factory` = the **FACTORY** (just for `factoryFound`)
- `promise` = the promise returned by the **FACTORY** (just for `promiseCreated`)

### error handling

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.CircularDependencyError, function(error) {
    /* just on circular dependencies... */
  }
  .catch(function(error) {
    /* on any error... */
  })
  .then(function(variance) {
    /* on success... */
  })
```

[click here for all error types and how to catch them](#errors)

### resolvers

**~~ RESOLVERS ARE LIKELY TO CHANGE IN THE FUTURE ~~**

resolvers add a level of indirection that allows you to
intercept the lookup of factories and values
in containers.

resolvers must be pure (deterministic) functions: given the same inputs they must return the same outputs.
they must not depend on uncontrollably changing factors like randomness or time or external services

there are 
but the same is true for value resolvers -
just replace **FACTORY** with **VALUE** in your mind.

a factory resolver is just a function that takes a container and a
name and returns a factory or `null`.

by default hinoki uses the `hinoki.defaultFactoryResolver` that simply
looks up the name in the containers `factories` property.

by adding `

those take an additional third argument

has a single factoryResolver that resolves factories in the **factories** object.
you can manipulate the resolvers:

```javascript
container.factoryResolvers.push(myFactoryResolver);
```

resolvers can be used to 

resolvers can be used to generate factories and values on the fly.
they can return factories without them being in `container.factories`.
a resolver could respond to `getUserWhereId` with a function

interesting alternative to rubys method missing

## reference

### API

#### `hinoki.get`

takes one or many **CONTAINERS** and one or many **NAMES**.

returns a [bluebird](https://github.com/petkaantonov/bluebird) promise that is resolved with an value (for one name) or an array of values (for many names).
the promise is rejected in case of [errors](#errors).
side effect the container

```javascript
hinoki.get(container, 'variance')
  .then(function(variance) {
    /* ... */
  });
```

```javascript
hinoki.get(container, ['variance', 'mean'])
  .spread(function(variance, mean) {
    /* ... */
  });
```

```javascript
hinoki.get([container1, container2], ['variance', 'mean'])
  .spread(function(variance, mean) {
    /* ... */
  });
```

you can pass a function as a third argument which is called
on various events (to see exactly what is going on under the hood which is useful for debugging).

```javascript
hinoki.get(container, 'variance', console.log)
  .then(function(variance) { /* ... */ })
  .catch(function(error) { /* ... */ });
```

#### `hinoki.parseFunctionArguments`

#### `hinoki.getNamesToInject`

#### `hinoki.resolveFactoryInContainers`

#### `hinoki.resolveValueInContainers`

### errors

#### `hinoki.CircularDependencyError`

when there is a cycle in the dependency graph described by the factory dependencies

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.CircularDependencyError, function(error) { /* ... */ });
```

#### `hinoki.UnresolvableFactoryError`

when no resolver returns a factory for a name

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.UnresolvableFactoryError, function(error) { /* ... */ });
```

#### `hinoki.ExceptionInFactoryError`

when a factory throws an error

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.ExceptionInFactoryError, function(error) { /* ... */ });
```

#### `hinoki.PromiseRejectedError`

when a factory returns a promise and that promise is rejected

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.PromiseRejectedError, function(error) { /* ... */ });
```

#### `hinoki.FactoryNotFunctionError`

when a resolver returns a value that is not a function

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.FactoryNotFunctionError, function(error) { /* ... */ });
```

#### `hinoki.FactoryReturnedUndefinedError`

when a factory returns undefined

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.FactoryReturnedUndefinedError, function(error) { /* ... */ });
```

## changelog

## [license: MIT](LICENSE)
