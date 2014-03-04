# hinoki

[![Build Status](https://travis-ci.org/snd/hinoki.png)](https://travis-ci.org/snd/hinoki)

**magical inversion of control for nodejs**

hinoki is a powerful and flexible asynchronous dependency resolution and dependency injection system
designed to manage complexity in nodejs applications.

hinoki is inspired by [prismatic's graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife) and [angular's dependency injection](http://docs.angularjs.org/guide/di).

hinoki is used for the dependency injection part of an upcoming web-application-library.

*hinoki takes its name from the hinoki cypress, a tree that only grows in japan and is the preferred wood for building palaces, temples and shrines.*

### index

- [warning](#warning)
- [install](#install)
- [get started](#get-started)
- [events](#events)
- [default containers](#default containers)
- [custom containers](#custom containers)

### warning

hinoki is beta software.

it has a large test suite and is already used in production.

the documentation in this readme is incomplete.

it is most likely going to change a lot.

use at your own risk!

### install

```
npm install hinoki
```

**or**

put this line in the dependencies section of your `package.json`:

```
"hinoki": "0.3.0-beta.4"
```

then run:

```
npm install
```

### get started

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

container.emitter.on('any', console.log);

hinoki.inject(container, function(mean) {
  console.log(mean);  // -> 3
});
```

### the hinoki model

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

### events

#### instanceFound

emitted whenever an instance is requested and already found in the
`instances` property of a container

```javascript
{
    event: 'instanceFound'
    id: /* array of strings */,
    value: /* the instance that was created */,
    container: /* container */
}
```

#### instanceCreated

emitted whenever an instance is requested, was not found, the factory was called
returns an instance that is not a [thenable](http://promises-aplus.github.io/promises-spec/).

payload:

```javascript
{
  event: 'instanceCreated'
  id: /* array of strings */,
  value: /* the instance that was created */,
  container: /* container */
}
```


### default containers

call `hinoki.newContainer()` to get a container with sensible default behaviour:

```javascript
container = hinoki.newContainer()
```

optionally pass in factories and instances as arguments.

a container created with `hinoki.newContainer()`:
has an **emitter** property that is an event emitter.
emits [events](#events) through it.

you can subscribe to all events by subscribing to the `any` event.
this is useful for debugging:

```javascript
container.emitter.on('any', console.log);
```

errors are emitted as the `error` event.
`error` events are treated as a special case in node.
if there is no listener for it, then the default action is to print a stack
trace and exit the program.

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

### custom containers

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
- **emit** is a function that takes a container and an event

### license: MIT
