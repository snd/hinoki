# hinoki

[![NPM version](https://badge.fury.io/js/hinoki.svg)](http://badge.fury.io/js/hinoki)
[![Build Status](https://travis-ci.org/snd/hinoki.svg?branch=master)](https://travis-ci.org/snd/hinoki)

**magical inversion of control for nodejs and the browser**

hinoki is a powerful and flexible asynchronous dependency injection system
designed to manage complexity in large applications.

hinoki is inspired by [prismatic's graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife) and [angular's dependency injection](http://docs.angularjs.org/guide/di).

*hinoki takes its name from the hinoki cypress, a tree that only grows in japan and is the preferred wood for building palaces, temples and shrines...*

### hinoki features

- [large test suite](test)
- [just ~500 lines of code](src/hinoki.coffee)
- containers are just data plain old javascript objects and can be
manipulated at will
- restricted mutable state
- a simple carefully-designed (underlying) model
flexible core
that enables a lot of emerging functionality to be build with it.
- no global / module-level state (state only lives in containers)
- decomplected
- completely asynchronous
- battle-tested on production
- data all the things
- works in [node.js](#nodejs-setup) and in the [browser](#browser-setup)
- powerful error handling and catching using bluebirds catch
- introspection
- powerful debugging
- multiple containers
- ability to intercept

#### ~~ HINOKI IS A WORK IN PROGRESS ~~

it is used in production and growing with the challenges encountered there.

hinoki will always stay true to its core principles.

- a functional data-driven rather than object oriented approach
- small elegant codebase
- simple, well-thought-out carefully-designed

### todo

annotate via $inject

### index

- [why hinoki?](#why-hinoki)
- [node.js setup](#why-hinoki)
- [getting started & basic concepts](#getting-started-basic-concepts)
- [advanced concepts](#advanced-concepts)
- [api reference](#api-reference)
- [use cases](#use-cases)
  - [structuring computation](#structuring computation)
  - [structuring async computation]()
  - [structuring applications]()
  - [web application development]()
- advanced concepts
- [errors](#errors)
- [containers](#containers)
- [collaboration](#license-mit)
- [license](#license-mit)

## why hinoki?

system of such pieces where some depend on others

software systems are composed of many pieces that depend on
each other in various ways.

libraries, functions for accessing the database

building blocks

simplifies getting data to where its needed

programming against an interface.

wire up closures on the fly

a lot more testable

hinoki allows you to declare the ways in which those pieces
depend on each other and can then resolve the dependencies automatically.

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

*its best to fetch bluebird with [bower](http://bower.io/), [hinoki with npm](https://www.npmjs.org/package/hinoki) and then use
a build system like [gulp](http://gulpjs.com/) to bring everything together*

## getting started & basic concepts

in the world of hinoki an **ID** is the name for a piece of the system, a contract.
building block.

an **INSTANCE** is the value of an **ID**:
it could be a function, a piece of data, an object, a library...

```javascript
var instances = {
  xs: [1, 2, 3, 6]
};
```

a **FACTORY** for an **ID** is a function that takes
the **INSTANCES** of the **ID's** dependencies
and returns an **INSTANCE** of the **ID**:

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

a **CONTAINER** manages the **FACTORIES** and **INSTANCES** for a set of **IDS**:

```javascript
var container = hinoki.newContainer(factories, instances);
```

a **CONTAINER** can be asked for the **INSTANCE** of an **ID**:

```javascript
hinoki.get(container, 'mean').then(function(mean) {
  console.log(mean);  // -> 3
});
```

the instances will be created and cached in the container

```javascript
console.log(container.instances);
// ->
// { xs: [ 1, 2, 3, 6 ],
//   count: 4,
//   mean: 3 }
```

asking for a cached **ID** again will return the cached **INSTANCE**.

```javascript
hinoki.get(container, 'count').then(function(count) {
  console.log(mean);  // -> 3
});
```

asking for an uncached **ID** will ask for the 
and cache all that are not already cached.

```javascript
hinoki.get(container, 'variance').then(function(variance) {
  console.log(variance);  // -> 3.5

  console.log(container.instances);
  // ->
  // { xs: [ 1, 2, 3, 6 ],
  //   count: 4,
  //   mean: 3,
  //   meanOfSquares: 12.5,
  //   variance: 3.5 }
});

```

it's often useful for multiple **CONTAINERS** to use the same **FACTORIES**
but different **INSTANCES**

```javascript
var anotherInstances = {
  xs: [2, 3, 4, 5]
};

var anotherContainer = hinoki.newContainer(factories, anotherInstances);

hinoki.get(anotherContainer, 'mean').then(function(mean) {
  console.log(mean);  // -> 3.5
});
```

a **CONTAINER** owns **INSTANCES**.

use **CONTAINERS** to control scope and lifetime of **INSTANCES**.

just use a new **CONTAINER** whenever you need a fresh scope.

[see the whole example again](example/computation.js)

## advanced concepts

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

### parsing dependencies from factory function arguments

```javascript
var factory = function(variance, mean) {
  /* ... */
};

var dependencyIds = hinoki.getFunctionArguments(factory);
// -> ['variance', 'mean']

hinoki.get(container, dependencyIds).spread(factory);
```

asks container for `variance` and `mean` and calls `factory` with them.

### multiple containers

hinoki supports multiple containers.

containers are asked in order from first to last.

instances are added to the container that resolved the factory.

factories can depend on dependencies in succeeding containers.

[see example](example/request.js) ...you get the idea ;-)

this enables new possibilities for web development. **demo application coming soon!!**

### instance resolvers



$inject

a container manages names

an instance resolver is a function that takes a container and
an id and returns an instance.

a resolver takes (resolves) an id and returns a factory

a resolver must be pure and always return the same factory or a factory
that behaves identically
of the same id

## api reference

### `hinoki.get`

takes one or many **CONTAINERS** and one or many **IDS**.

returns a [bluebird](https://github.com/petkaantonov/bluebird) promise that is resolved with an instance (for one id) or an array of instances (for many ids).
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

### `parseFunctionArguments`

### `resolveFactoryInContainers`

### `resolveInstanceInContainers`

### use cases


##### application

load sync example

##### web application development

the thing hinoki was designed for in the first place.

using hinokis capability to use multiple containers
it is

an implementation is left as an exercise for the reader.

## logging & debugging

pass in a callback as the second

## error handling

catch any error

```javascript
hinoki.get(container, 'variance')
  .catch(function(error) { /* ... */ });
```

or catch individual error types using bluebirds catch

#### CircularDependencyError

when there is a cycle in the dependency graph described by the factory dependencies

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.CircularDependencyError, function(error) { /* ... */ });
```

#### UnresolvableFactoryError

when no resolver returns a factory for an id

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.UnresolvableFactoryError, function(error) { /* ... */ });
```

#### ExceptionInFactoryError

when a factory throws an error

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.ExceptionInFactoryError, function(error) { /* ... */ });
```

#### PromiseRejectedError

when a factory returns a promise and that promise is rejected

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.PromiseRejectedError, function(error) { /* ... */ });
```

#### FactoryNotFunctionError

when a resolver returns a value that is not a function

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.FactoryNotFunctionError, function(error) { /* ... */ });
```

#### FactoryReturnedUndefinedError

when a factory returns undefined

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.FactoryReturnedUndefinedError, function(error) { /* ... */ });
```

### containers

call `hinoki.newContainer()` to get a container with sensible default behaviour:

```javascript
container = hinoki.newContainer()
```

optionally pass in factories and instances as arguments.

add your own factories by sticking them into the factories object.

a container created with `hinoki.newContainer()`:
has an **instances** property that is an object.
sets instances in the **instances** object.

has a single instanceResolver that resolves instances in the **instances** object.
you can manipulate the resolvers:

```javascript
container.instanceResolvers.push(myInstanceResolver);
```

has a single factoryResolver that resolves factories in the **factories** object.
you can manipulate the resolvers:

```javascript
container.factoryResolvers.push(myFactoryResolver);
```

## container spec

hinoki accepts as a container any object with the following properties that behave as described:

- **factoryResolvers** is an array of functions that each take a *container* and an *id*, return either a *factory function* or *null* and have no side effects
- **instanceResolvers** is an array of functions that each take a *container* and an *id*, return an *instance value* and have no side effects
- **setInstance** is a function that takes a *container*, an *id* and an *instance value* and side effects the container
in such a way that the *instance value* will be returned by an instance resolver for that *id* in the future
- **setUnderConstruction** is a function that takes a *container*, an *id* and a *promise* and side effects the
the container in such a way that **getUnderConstruction** will return that *promise* for that *id* in the future
- **unsetUnderConstruction** is a function that takes a *container* and an *id* and side effects the container in such a way
that **getUnderConstruction** will return nothing for that *id* in the future
- **getUnderConstruction** is a function that takes a *container* and an *id* and returns the *promise* that was previously
set or unset by **setUnderConstruction** or **unsetUnderConstruction**

## license: MIT
