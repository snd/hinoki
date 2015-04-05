# hinoki

[![NPM Package](https://img.shields.io/npm/v/hinoki.svg?style=flat)](https://www.npmjs.org/package/hinoki)
[![Build Status](https://travis-ci.org/snd/hinoki.svg?branch=master)](https://travis-ci.org/snd/hinoki/branches)
[![Dependencies](https://david-dm.org/snd/hinoki.svg)](https://david-dm.org/snd/hinoki)

**magical inversion of control for Node.js and the browser**

<!---
hands on examples are big
abstract information is small
-->

<!---
> beautiful inversion of control for nodejs and the browser

hinoki is a powerful and flexible asynchronous dependency injection system

ultra simple and ultra fast sync and async dependency injection

ultra lightweight

dead simple

very fast
-->

hinoki is a powerful yet simple asynchronous dependency injection system
designed to manage complexity in applications and (asynchronous) computation.

<!---
perfect for managing complexity
predestined to manage complexity

### is it any good ?

more abstactly:
defining the structure between values.
asking for specific values and having hinoki figure out

enables some things that are not usually possible with javascript
and which can greatly reduce the code needed to accomplish some things
and the complexity of the remaining code.
-->

<small>
hinoki is inspired by [prismatic's graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife) and [angular's dependency injection](http://docs.angularjs.org/guide/di).
</small>

<small>
hinoki takes its name from the hinoki cypress,
a tree that only grows in japan and is the preferred wood for building palaces,
temples and shrines.
</small>

<!---
</small>
we hope you do to !

we prefer hinoki as the material for building amazing web applications, virtual palaces.  
we hope you prefer hinoki as the substance/material for building virtual palaces, temples and shrines.
</small>
-->

<!---
### testimonials
-->

> Hinoki seems to be the least surprising IoC container available for Node.  
> I definitely do like its ascetic worldview.  
> Thanks a lot for this!  
> <small>[@andrey](https://github.com/snd/hinoki/issues/3)</small>

<!---
### features
-->

<!---
write this in text form as well
-->

<!---
- stable
  - [large, thorough test suite](test)
  - battletested for 1.5 years in production
- anywhere
  - Node.js
  - IO.js
  - AMD
  - browser
-->

<!---
- careful, simple design
- bare
- makes little assumptions about how you might use it
- sound model
- powerful
  - use multiple stacked lifetimes
- powerful
  -
- simple
  - truly simple, carefully-designed underlying model and terminology and API
  - [small (~500 LOC), elegant, hackable codebase](src/hinoki.coffee)
  - carefully designed features and API
- full support for promise based asynchchronous
  - works with promises
- functional, value-oriented, data, closures
- hinoki is a bendable [flexible] base for your [individual] dependency injection needs
- [simulate method-missing by generating dependencies on demand]()
- powerful error handling using promises
- its so fast that you wont even notice it
-->

``` javascript
var hinoki = require('hinoki');
```

### **_values_** are the building blocks of your application

hinoki is useful when your problem, application, problem or computation
consists of multiple **_values_** that depend on each other.

<!---
most applications, problems or computations
-->

a **_value_** can be anything: an integer, an object, a function, a class, ...

for example:  
the **_value_** of *a controller action* might depend on  
the **_value_** of *a function to retrieve some data from a database* which might depend on
the **_value_** of *a connection pool* which might depend on  
the **_value_** of *an url to the database*...

<!---
the **_value_** of *a function that checks if the current user is permitted to an action* might depend on  
the **_value_** of *the current users rights* which might depend on  
the **_value_** of *the current user* which might depend on  
the **_value_** of *the id of the current user* which might depend on  
the **_value_** of *the session* which might depend on  
the **_value_** of *the cookie*...

-->

<!---
insert sketch here
-->

a **_name_** is - you guessed it - the name of a **_value_**.

<!---

<small>
those computations can even be [asynchronous](#on-promises).
</small>
-->

### **_factories_** are functions that return **_values_**

within hinoki you use **factories** to model
the [dependency graph](https://en.wikipedia.org/wiki/Dependency_graph) of your
application, problem or computation.

a **_factory_** has a **_name_**.
a **_factory_** takes **_dependencies_** as arguments and returns the **_value_**
for its **_name_**.
the **_dependencies_** are **_values_** as well.
the **_names_** of the arguments are the **_names_** of the **_values_**
the **_factory_** depends on.

let's imagine for a moment that you want to compute several
interdependent statistics of a series of numbers.

<!---
let's use that knowledge to define the **_factories_** of our statistics example:
-->

let's use our knowledge to define the **_factories_** for that:

``` javascript
var factories = {
  sumFn: function() {
    return function(xs) {
      return xs.reduce(function(acc, x) { return acc + x; }, 0);
    }
  },
  numbersSquared: function(numbers) {
    return numbers.map(function(x) { return x * x; });
  },
  numbersSorted: function(numbers) {
    return numbers.slice().sort();
  }
  count: function(numbers) {
    return numbers.length;
  },
  median: function(numbersSorted, count) {
    return numbersSorted[Math.round(count)];
  },
  mean: function(numbers, count, sumFn) {
    return sumFn(numbers) / count;
  },
  meanOfSquares: function(numbersSquared, count, sumFn) {
    return sumFn(numbersSquared) / count;
  },
  variance: function(mean, meanOfSquares) {
    return meanOfSquares - mean * mean;
  }
};
```

<!---
the idea is that you define and the can evaluate parts of the graph.

-->

the *factory* for the *product* `variance` depends on
the *products* `mean`and `meanOfSquares`...

a factory is a recipe to create the value in the presence of
the values that are the value's dependencies.

a name is associated with both a value and a factory

lifetimes manage names.
within a lifetime there is either a value for a name.
or there

### _lifetime_ = _factories_ + _values_

**lifetimes** are used to record the values returned by factories.

a **_lifetime_** is simply a tuple of **_factories_** and **_values_**.

**_values_**

the concrete values are cached in the lifetime.
and the concrete **_values_** retrieved.

lifetimes manage state.
lifetimes manage how long state lives.
lifetimes manage the lifetime of certain state.

lifetimes also hold hooks that let
more on that [later](#on-hooks)

associate an object with initial values that also records
the values returned by factories with an object containing factories.

values returned by factories are cached in lifetimes

**lifetimes** manage state:
values for
and factories for those values that have

``` javascript
var lifetime = {
  factories: factories,
  values: {
    numbers: [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  }
};

```

**lifetimes** are plain old javascript objects.

### getting a *value* in a *lifetime*

we can give hinoki a lifetime and a name and it will kindly give us a
[promise](...) that will resolve to the value of that name:

``` javascript
hinoki(lifetime, 'mean').then(function(mean) {
  console.log(mean); // ->
});
```

hinoki will side effect the lifetime by caching values in it:

``` javascript
console.log(lifetime.values)
// -> {
//   ...
// }
```

<small>you can disable caching by setting the `$nocache` property of a factory to `true`</small>

if we pass in an array of **_names_** hinoki will return a promise
that resolves to the array of **_values_** for those **_names_**:

``` javascript
hinoki(lifetime, ['mean', 'variance']).spread(function(mean, variance) {
  console.log(mean); // ->
  console.log(variance); // ->
});
```

if we pass in a function as the second argument hinoki will parse the dependencies
from the function arguments

``` javascript
hinoki(lifetime, function(variance, median) {
  console.log(variance); // ->
  console.log(median); // ->
}).error(function(error) {

});
```

if we want to use a different series of numbers we can just use a new lifetime.

<small>
hinoki always returns a promise: to normalize synchronous and asynchronous
dependencies and to simplify error handling.
</small>

<small>
and if something goes wrong the promise will be rejected with an [error](#on-errors).
</small>

hinoki has only generated

if we ask again for `meanOfSquares` again it is not computed
again instead

### on promises

see ... for a real async example

<!---
### stacking lifetimes

you can use this to

requests
events

inside the callback for the request/event you would create a new lifetime
and use both that and the ... lifetime

the ... lifetime is shared by all requests

overlaying

-->

<!---
insert sketch
-->

<!---
### factory objects
-->

<!---
### factory arrays
-->

<!---
### sources
-->

<!---
### on hooks
-->

<!---

- [a functional data-driven approach with localized mutable state](#lifetimes)
- a simple carefully-designed (underlying) model
flexible core
a simple, carefully-designed and flexible core with many useful qualities

Use multiple lifetimes with different lifetimes that reference each Other

lifetimes with lower lifetimes can depend on lifetimes with higher lifetimes

A is active during a request but depends on some Things in b which lives through the entire process

hinoki lifetimes

lifetimes can depend on other lifetimes
granular control over
that allows functionality/features to emerge around it
that enables a lot of emerging functionality to be build with it.
- decomplected
- [asynchronous dependencies through promises](#asynchronous)
- works in [node.js](#nodejs-setup) and in the [browser](#browser-setup)
- [powerful error handling](#error-handling)
- [powerful logging & debugging for every step of the dependency injection process](#logging-debugging)
- [the ability to use multiple lifetimes opens up interesting possibilities](#multiple-lifetimes)
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
  - [lifetimes](#lifetimes)
  - [asynchronous dependencies](#asynchronous-dependencies)
  - [parsing dependencies from function arguments](#parsing-dependencies-from-function-arguments)
  - [dependencies of factory functions](#dependencies-of-factory-functions)
  - [null and undefined](#null-and-undefined)
  - [multiple lifetimes](#multiple-lifetimes)
  - [logging & debugging](#logging-debugging)
  - [error handling](#error-handling)
  - [resolvers](#resolvers)
- [reference](#reference)
  - [API](#api)
    - [`hinoki`](#hinokiget)
  - [errors](#errors)
- [changelog](#changelog)
- [license](#license-mit)

## why hinoki?

system of such pieces where some depend on others

software systems are composed of many pieces that depend on
each other in various ways.

libraries, functions for accessing the database

hinoki solves the problem of composing all those parts

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

dont use hinoki dependencies for libraries

use them for application code!!!

By making it very easy to
Get a hold of a Part of the system

Don't repeat yourself is encouraged

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
hinoki(container, 'mean').then(function(mean) {
  console.log(mean);  // -> 3
});
```

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
hinoki(container, 'count').then(function(count) {
  console.log(mean);  // -> 3
});
```

```javascript
hinoki(container, 'variance').then(function(variance) {
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

hinoki(otherContainer, 'mean').then(function(mean) {
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

var dependencyNames = hinokiFunctionArguments(factory);
// -> ['variance', 'mean']

hinoki(container, dependencyNames).spread(factory);
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

hinoki(container, 'acd', console.log).then(function(acd) {
  console.log(acd);  // -> 'acd'
  // dependency names have been cached
  console.log(factories.a.$inject); // -> []
  console.log(factories.acd.$inject); // -> ['ac', 'd']
});
```

[source](example/dollar-inject.js)

### null and undefined

a **VALUE** can be `null`

if a factory returns `undefined` the promise is rejected with a



if a factory returns `null` then the value `null` is cached and returned.



### multiple containers

hinoki supports multiple containers.

containers are asked in order from first to last.

values are added to the container that resolved the factory.

factories can depend on dependencies in succeeding containers.

[see example](example/request.js) ...you get the idea ;-)

this opens new possibilities for web development - demo application coming soon!

### scope


### logging & debugging

pass in a callback as the third argument to `hinoki`
and it will be called on various steps during the dependency injection process:

```javascript
hinoki(container, 'variance', console.log)
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

filter on event type

### error handling

```javascript
hinoki(container, 'variance')
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

... in a structured fashion

```javascript
container = {
  factoryResolvers: [
    function(container, name, inner) {
      var factory = inner();
      if (factory) {
        return factory;
      }
      if name is '
    }
  ]
};
```

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

#### `hinoki`

takes one or many **CONTAINERS** and one or many **NAMES**.

returns a [bluebird](https://github.com/petkaantonov/bluebird) promise that is resolved with an value (for one name) or an array of values (for many names).
the promise is rejected in case of [errors](#errors).
side effect the container

```javascript
hinoki(container, 'variance')
  .then(function(variance) {
    /* ... */
  });
```

```javascript
hinoki(container, ['variance', 'mean'])
  .spread(function(variance, mean) {
    /* ... */
  });
```

```javascript
hinoki([container1, container2], ['variance', 'mean'])
  .spread(function(variance, mean) {
    /* ... */
  });
```

you can pass a function as a third argument which is called
on various events (to see exactly what is going on under the hood which is useful for debugging).

```javascript
hinoki(container, 'variance', console.log)
  .then(function(variance) { /* ... */ })
  .catch(function(error) { /* ... */ });
```

#### `hinoki.parseFunctionArguments`

#### `hinokiNamesToInject`

#### `hinoki.resolveFactoryInContainers`

#### `hinoki.resolveValueInContainers`

### errors

#### `hinoki.CircularDependencyError`

when there is a cycle in the dependency graph described by the factory dependencies

```javascript
hinoki(container, 'variance')
  .catch(hinoki.CircularDependencyError, function(error) { /* ... */ });
```

#### `hinoki.UnresolvableFactoryError`

when no resolver returns a factory for a name

```javascript
hinoki(container, 'variance')
  .catch(hinoki.UnresolvableFactoryError, function(error) { /* ... */ });
```

#### `hinoki.ExceptionInFactoryError`

when a factory throws an error

```javascript
hinoki(container, 'variance')
  .catch(hinoki.ExceptionInFactoryError, function(error) { /* ... */ });
```

#### `hinoki.PromiseRejectedError`

when a factory returns a promise and that promise is rejected

```javascript
hinoki(container, 'variance')
  .catch(hinoki.PromiseRejectedError, function(error) { /* ... */ });
```

#### `hinoki.FactoryNotFunctionError`

when a resolver returns a value that is not a function

```javascript
hinoki(container, 'variance')
  .catch(hinoki.FactoryNotFunctionError, function(error) { /* ... */ });
```

#### `hinoki.FactoryReturnedUndefinedError`

when a factory returns undefined

```javascript
hinoki(container, 'variance')
  .catch(hinoki.FactoryReturnedUndefinedError, function(error) { /* ... */ });
```

-->

<!---
## changelog
-->

### future plans

- ok'ish readme
- merge `beta` into `master`
- merge `experiments` into `master`
- finish documentation
- test the examples
- better debugging solution
- replace resolvers by
  - sources
    - `lifetime.factories` can be array of sources
      - sources are tried in order
      - a source is either an object of factories
      - or a forge
        - `function(name : string) -> factory or undefined`
        - used for forge
  - proxies or wrappers or decorators
    - `mapFactory(factory, name)`
      - used for tracing
    - `mapValue(value, name)`
  - mappers
    - `mapName(string) -> string`
      - used for aliasing
- implement [factory arrays](https://github.com/snd/hinoki/issues/3)
- implement [factory objects](https://github.com/snd/hinoki/issues/3)
- port to js
  - use compiled js and go from there
- performance
  - add benchmark
    - what ?
    - microbenchmark
  - record benchmark results
  - assert optimization status in unit test
  - use lodash
  - make sure that all but the outer function can be optimized
    - make inner functions monomorphic
  - pick low hanging fruits to improve performance
  - ensure that optimizations actually improved performance
- logo
- reddit
- hackernews

## [license: MIT](LICENSE)
