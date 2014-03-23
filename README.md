# hinoki

[![Build Status](https://travis-ci.org/snd/hinoki.png)](https://travis-ci.org/snd/hinoki)

**magical inversion of control for nodejs and the browser**

hinoki is a powerful and flexible asynchronous dependency resolution and dependency injection system
designed to manage complexity in large nodejs applications.

hinoki is inspired by [prismatic's graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife) and [angular's dependency injection](http://docs.angularjs.org/guide/di).

[hinoki is used for dependency injection in an upcoming web-application-library](#web-application-development)

*hinoki takes its name from the hinoki cypress, a tree that only grows in japan and is the preferred wood for building palaces, temples and shrines.*

**hinoki is beta software.**

**it has a large test suite and is already used in production.**

**the documentation in this readme is work in progress, incomplete and does not describe
everything that is possible with hinoki.**

### index

- [install](#install)
- [tutorial](#tutorial)
- [example](#example)
- [api](#api)
- [use cases](#use-cases)
  - [structuring computation](#structuring computation)
  - [structuring async computation]()
  - [structuring applications]()
  - [web application development]()
- [errors](#errors)
- [containers](#containers)
- [license](#license-mit)

### install

```
npm install hinoki
```

**or**

put this line in the dependencies section of your `package.json`:

```
"hinoki": "0.3.0-beta.5"
```

then run:

```
npm install
```

### tutorial

hinoki manages ids.

ids
ids are just strings

names for a piece of data, function

system of such pieces where some depend on others

containers manage ids

ids are either realized or not


factories

make, create

get

a factory

$inject

simplifies getting data to where its needed

hinoki can work with multiple containers

containers are asked in order

instances are added to the container that resolved the factory

a container manages names

an instance resolver is a function that takes a container and
an id and returns an instance.

programming against an interface.

wire up closures on the fly

### instances and factories and stuff

If a factory returns a thenable (bluebird or q promise) it will 

### factory resolver

a resolver takes (resolves) an id and returns a factory

a resolver must be pure and always return the same factory or a factory
that behaves identically
of the same id

### example

```javascript
var hinoki = require('hinoki');

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

var instances = {
  xs: [1, 2, 3, 6]
};

var container = hinoki.newContainer(factories, instances);

var debug = console.log;

hinoki.get(container, 'mean', debug).then(function(mean) {
  console.log(mean);  // -> 3
});
```

### api

#### `get`

takes one or many **containers** and one or many **ids**.

returns a [bluebird](https://github.com/petkaantonov/bluebird) promise that is resolved with an instance (for one id) or an array of instances (for many ids).

```javascript
hinoki.get(container, 'variance')
  .then(function(variance) { /* ... */ });
```

```javascript
hinoki.get(container, ['variance', 'mean'])
  .spread(function(variance, mean) { /* ... */ });
```

```javascript
hinoki.get([container1, container2], ['variance', 'mean'])
  .spread(function(variance, mean) { /* ... */ });
```

the promise is rejected in case of [errors](#errors)

you can pass a function as a third argument which is called
on various events (to see exactly what is going on under the hood which is useful for debugging).

```javascript
hinoki.get(container, 'variance', console.log)
  .then(function(variance) { /* ... */ })
  .catch(function(error) { /* ... */ });
```

you can inject into a factory as follows

```javascript
var factory = function(variance, mean) { /* ... */ };

hinoki.get(container, hinoki.getFunctionArguments(factory)).spread(factory);
```

#### `parseFunctionArguments`

#### `resolveFactoryInContainers`

#### `resolveInstanceInContainers`

### use cases


##### application

load sync example

##### web application development

the thing hinoki was designed for in the first place.

using hinokis capability to use multiple containers
it is

an implementation is left as an exercise for the reader.

### errors

catch individual error types using bluebirds catch

#### `CircularDependencyError`

when there is a cycle in the dependency graph described by the factory dependencies

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.CircularDependencyError, function(error) { /* ... */ });
```

#### `UnresolvableFactoryError`

when no resolver returns a factory for an id

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.UnresolvableFactoryError, function(error) { /* ... */ });
```

#### `ExceptionInFactoryError`

when a factory throws an error

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.ExceptionInFactoryError, function(error) { /* ... */ });
```

#### `PromiseRejectedError`

when a factory returns a promise and that promise is rejected

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.PromiseRejectedError, function(error) { /* ... */ });
```

#### `FactoryNotFunctionError`

when a resolver returns a value that is not a function

```javascript
hinoki.get(container, 'variance')
  .catch(hinoki.FactoryNotFunctionError, function(error) { /* ... */ });
```

#### `FactoryReturnedUndefinedError`

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

### license: MIT
