# hinoki

*this is release candidate 1 for version 1.0.0.
implementation and tests are complete.
the documentation in this readme is not yet finished.*

<!--
the readme doesnt have to be perfect.
you can always improve it later
-->

[![NPM Package](https://img.shields.io/npm/v/hinoki.svg?style=flat)](https://www.npmjs.org/package/hinoki)
[![Build Status](https://travis-ci.org/snd/hinoki.svg?branch=master)](https://travis-ci.org/snd/hinoki/branches)
[![Dependencies](https://david-dm.org/snd/hinoki.svg)](https://david-dm.org/snd/hinoki)

**lean and mean dependency injection and more for Node.js and browsers**

whenever you have a system (application, computation, query, ...) whose elements
(data, functions, ...) depend
on each other in complex and sometimes asynchronous ways
hinoki can help express in a simple, testable, elegant way.

a system could be an entire application, a query with many asynchronous parts
or
in any case hinoki

*the newest version 1.0.0-rc.1 introduces massive breaking changes.
if you used an earlier version of hinoki please read this new readme carefully.
future changes will be documented in the [changelog](#changelog).
future versions will use [semver](http://semver.org/).*

> Hinoki seems to be the least surprising IoC container available for Node.  
> I definitely do like its ascetic worldview.  
> Thanks a lot for this!  
> [andrey](https://github.com/snd/hinoki/issues/3)

hinoki is inspired by prismatic's fantastic [graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife)

*hinoki takes its name from the hinoki cypress,
a tree that only grows in japan and is the preferred wood for building palaces,
temples and shrines.  
may hinoki become the building material for your digital palaces too !*

<!---
</small>
we hope you do to !

i hope you

we prefer hinoki as the material for building amazing web applications,
virtual palaces.  
we hope you prefer hinoki as the substance/material for
building virtual palaces, temples and shrines.
</small>
-->

[why is this useful ? why should i read on ?](#why)  
[how to get this ?](#how-to-get-this)  
[give me examples](#how-to-get-this)  
[core concepts](#how-to-get-this)  
[core concepts](#how-to-get-this)  
[how do i contribute ?](#how-to-contribute)

[how to get it]()
[i'd like to see some examples]()
[give me a detailed rundown of all the concepts]()
[terminology]()

link all occurences of keywords to the terminology.

### why is this useful ? why should i read on ?

**why you should you read on**

whenever you have a system (application, computation, query, ...) whose elements
(data, functions, ...) depend
on each other in complex and sometimes asynchronous ways
hinoki can help express in a simple, testable, elegant way.

<!--
whenever you have a system whose components depend on each other
in complex and/or asynchronous ways.
hinoki is useful in reducing 
complexity
-->

this sounds abstract. hinoki is abstract !
there's a lot you can do with it.

because of that i currently think the best way to explain hinoki is
to guide you through every aspect of its functioning
and then let you apply 


we use hinoki in the large:
to break up large applications into
many small, self-contained parts that 
put the parts of our applications together.
manage complexity.
testable.
contain less duplicate code.
[see an example]()

we use hinoki in the small:
to
we are able to
to solve problems with multiple
interdependent asynchronously retrieved/computed values
with shorter, more elegant code.
[see an example]()

<!--
possibly insert reference to fragments here
-->

hinoki does dependency injection
in ways that are much simpler than 

in a style that is far removed from dependency 
but not your standard OOP, java dependency injection.

- it is well-thought-out
- asynchronous
- used in production
- fast
- simple
- flexible
- stable

the current version and abstractions are the result of
of constant use, careful thought, and multiple rewrites.

hinoki is simple: 

hinoki is powerful:

hinoki is carefully-designed:

hinoki is stable: it is 

hinoki is always asynchronous.

hinoki has been around for ... year

it has been through multiple refactorings and api changes.
- well-tested

hinoki is lean: it exports a single function.
the implementation is just 500 lines.


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

<!--
hinoki is fast
-->

<!--

## core concepts

software systems consists of **values**:
pieces of information and functionality:
strings, numbers, objects, functions, ...

very often **values** **depend** on other **values**.

for example:
a function that handles a request might depend on a function
that queries the database.
the function that queries the database might depend on a
database connection, some constants and some helper functions.
the database connection might depend on some configuration.

in Node.js **values** are often the result of asynchronous
callbacks or promises.

in a nutshell:
hinoki allows you to model those **dependencies** using standard javascript features:
**factories** are functions that take **dependencies**
and return **values**.
there's much more to hinoki.

whenever you have 
hinoki might come in handy
hinokis purpose is to resolve dependencies.

with hinoki you can describe your 
ask for a **value** and
**hinoki will do the rest!**

-->

### get it

```
npm install hinoki
```

```javascript
var hinoki = require('hinoki');
```

or

```
bower install hinoki
```

[lib/hinoki.js](lib/hinoki.js) supports [AMD](http://requirejs.org/docs/whyamd.html).  
if [AMD](http://requirejs.org/docs/whyamd.html) is not available it sets the global variable `hinoki`.

### you can think of hinoki as a [map/dictionary-datatype](https://en.wikipedia.org/wiki/Associative_array) with two additional levels of very useful indirection

we can even use hinoki like a map:

``` javascript
var lifetime = {
  one: 1,
  two: 2,
  three: 3,
};

hinoki(function() {}, lifetime, 'three').then(function(value) {
  assert(value === 3);
});
```

the first argument is the **source** function.
more on that in a bit.
here it does nothing.

the second argument is a **lifetime**.

a **lifetime** is a plain-old-javascript-object that maps
**keys** to **values**.

the third argument is the **key** we want to get the **value** of.

if we ask for a **key** and a **value**
is present for that **key** in the **lifetime** then `hinoki` will
return a promise that resolves exactly to that **value** !

that's what's going on in the example above.

`hinoki` will always return a promise.

it's not very useful. we could have used `lifetime.three` directly.
we'll get to the useful stuff in a bit !

---

we can also look up the **values** for multiple **keys**
in multiple **lifetimes** at once:

``` javascript
var lifetimes = [
  {one: 1},
  {one: 'one'},
  {two: 2, three: 3},
  {two: 'two'},
];

hinoki(function() {}, lifetimes, ['three', 'one', 'two'])
  .spread(function(a, b, c) {
    assert(b === 1);
    assert(c === 2);
    assert(a === 3);
  });
```

a **value** is returned from the first **lifetime** having a **key**.

---

we can even pass in a function as the third argument:

``` javascript
var lifetimes = [
  {one: 1},
  {two: 2},
  {three: 3},
];

hinoki(function() {}, lifetimes, function(two, one, three) {
  assert(one === 1);
  assert(two === 2);
  assert(three === 3);
  return two + three;
}).then(function(value) {
  assert(value === 5);
})
```

hinoki has just parsed the **keys** to look up from the *parameters*
of the function and called it with the right **values** as *arguments*.
remember this concept as it will be important soon !

in this case hinoki returns a promise that resolves to the
value (or promise) returned by the function.

that's an improvement but still not really what hinoki is about.

---

let's get to that !

what if we ask for a value that is not present in the **lifetime(s)** ?
``` javascript
var lifetime = {
  one: 1,
  two: 2,
  three: 3,
};

hinoki(function() {}, lifetime, 'four').then(function(value) {
  assert(value === 4);
});
```
the promise is rejected with an error:
```
Unhandled rejection NotFoundError: neither value nor factory found for `four` in path `four`
```

if we ask for a **key** and a **value** is **NOT PRESENT** for that **key**
in the **lifetime(s)** then hinoki will call the **source** function with the
**key**.  
here our **source** function always returns `undefined`.

this is the first useful level of indirection:
sources are for responding to values that are not present in lifetimes.
sources don't return a value directly.
they return a factory
factories return values.
this is the second useful level of indirection.

the **source** must return `null` (`undefined` is fine too)
or a **factory**.


a **factory** is simply a function:
a function that as has the **keys** of its **dependencies** as *parameters*,
expects/takes the **values** of its **dependencies** as *arguments*
and returns a **value**.

sources make factories.

factories make values.

let's see what happens when the **source** returns a **factory**:

``` javascript
var lifetime = {
  one: 1,
  two: 2,
  three: 3,
};

var source = function(key) {
  if (key === 'four') {
    return function(one, three) {
      return Promise.resolve(one + three);
    };
  }
};

hinoki(source, lifetime, 'four').then(function(value) {
  assert(value === 4);
  assert(lifetime.four === 4);
});
```

there's a lot going on. let's break it down:



if the **source** returns a **factory** then `hinoki`

method missing.

this is the second level of indirection.

so now if we ask again

that's not very convenient

hinoki caches **values** in lifetime.

and this is where

independent of how many sources and factories
and lifetimes you have

IT JUST WORKS!

this is the only type of side effect

now if we were to change the value of three
we are not effecting our first lifetime.

you can disable that by setting the `__nocache` property on the factory to `true`.

note that you can omit the lifetime alltogether
if 

there can already be a value present for a key

you call hinoki with either two

hinoki allows you to model those **dependencies** using standard javascript features:

a **key** is simply a string that uniquely identifies some **value**.

a **key** `A` can have an associated **factory**:  
a **factory** is just a *function*.
the *parameters* of a **factory** are interpreted as the **keys**
of the **dependencies** of the function.
a **factory** for the key `A` would take the **values** of the
**dependencies** as *arguments* and *return* the **value** associated with the
**key** `A`.

here's a very simple example to illustrate that:

``` javascript
var Promise = require('bluebird');
var hinoki = require('hinoki');

hinoki(
  {
    one: function() { return 1; },
    two: function(one) { return one + one; },
    three: function(one, two) { return Promise.resolve(one + two); },
  },
  'three'
).spread(function(value) {
  assert(value === 3);
});
```

hinoki exports a single function which can be called
with [two or three arguments](#ways-to-call-hinoki).

here we call it with two arguments.

the first argument is a **source**:

the second argument is a **key**.
hinoki returns a [promise](https://github.com/petkaantonov/bluebird)
that is resolved with the **value** for the **key**.

[click here to see exactly whats going on in this example.]()

this example is intentionally very simple.
[there's a whole lot more you can do with hinoki.]()

because some 
and some
hinoki supports multiple lifetimes (containers).
this enables per-request- and per-event-dependency-injection.

if you still think i'd be happy 




there's a lot you can do with sources.

method missing.
autogenerate.
check out umgebung
decorate to do tracing (checkout telemetry),
memoization, freezing, ...

## core concepts by example
## let's get started



## core concepts explained by examples

let's require hinoki:

``` javascript
var hinoki = require('hinoki');
```

let's revisit our simple example
but write it in a slightly different style:

``` javascript

var factories = {
  one: function() {
    return 1;
  },
  two: function(one) {
    return one + one;
  },
  three: function(one, two) {
    return Promise.resolve(one + two);
  },
};

var source = hinoki.source(factories);

hinoki(source, 'three').then(function(value) {
  assert(valueOfThree === 3);
});
```

there's already a lot going on here. let's break it down.

keyspace.
set of keys.

a key is just a string

we call hinoki with two arguments: a **source** and a **key**.

a **factory** is a function that has as arguments the **keys** of its dependent **values**

first, let's introduce some concepts

values can depend on other values

hinoki is a powerful yet simple asynchronous dependency injection system
designed to manage complexity in applications and (asynchronous) computation.



## value caching

<!---
## all the ways to call hinoki

hinoki exports a single function which can be called
with either 2 or 3 arguments.

the first argument must always either be a **source**
or something that can be converted to a **source**:
an object whose values are **factories** or 
or an array of sources
or an array of things that can be converted to a source.

the middle argument is optional and is either a **lifetime**
or an array of **lifetimes**.

the last argument is either a **key**, an array of **keys** or a **factory**.

hinoki will wrap the first argument in a source function unless
it already is a source function.



if no middle argument is given hinoki will throw away the lifetime.

## explain by example

but sources don't return values.
instead they return factories.
factories return values.

this way values can depend on other values by key.
a factory for a key creates the value for that key when called with the dependencies of that key.

what do we do with all those created values.

exports are factories

application example

-->

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

lean and mean

most behaviour is the simple result of [after] trying several more complex
solutions
-->

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


<!---
### testimonials
-->

<!---
### features
-->

<!---
write this in text form as well
-->

<!--

### **_values_** are the building blocks of your application

hinoki is useful when your problem, application, problem or computation
consists of multiple **_values_** that depend on each other.

-->

<!---
most applications, problems or computations
-->

<!--

a **_value_** can be anything: an integer, a function, a string, an object, a class, ...

for example:  
the **_value_** of *a controller action* might depend on  
the **_value_** of *a function to retrieve some data from a database* which might depend on
the **_value_** of *a connection pool* which might depend on  
the **_value_** of *an url to the database*...

-->

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

<!---

<small>
those computations can even be [asynchronous](#on-promises).
</small>
-->

<!--

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

-->

<!---
let's use that knowledge to define the **_factories_** of our statistics example:
-->

<!--

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
  },
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

-->

<!---
the idea is that you define and the can evaluate parts of the graph.

-->

<!--

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

-->

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

## changelog

future changes will be documented here

<!--
## how fast is this ?

version ... of hinoki
on a 2014 macbook air running iojs ... on date

lookups of 1 cached value

it should be fast enough
-->

## [license: MIT](LICENSE)
