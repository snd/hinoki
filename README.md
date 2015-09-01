# hinoki

*this is a release candidate for version 1.0.0.
implementation and tests are complete.
the documentation in this readme is not yet finished.
it's already useful though.
the newest version introduces massive breaking changes.
if you used an earlier version of hinoki please read this new readme carefully.
future changes will be documented in the [changelog](#changelog).
future versions will use [semver](http://semver.org/).*

<!--
the readme doesnt have to be perfect.
you can always improve it (later).

keep it as short as possible.
-->

<!--
start with an introduction that
sells hinoki and doesnt require scrolling.
create curiosity that will result in scrolling down.
-->

[![NPM Package](https://img.shields.io/npm/v/hinoki.svg?style=flat)](https://www.npmjs.org/package/hinoki)
[![Build Status](https://travis-ci.org/snd/hinoki.svg?branch=master)](https://travis-ci.org/snd/hinoki/branches)
[![Sauce Test Status](https://saucelabs.com/buildstatus/hinoki)](https://saucelabs.com/u/hinoki)
[![codecov.io](http://codecov.io/github/snd/hinoki/coverage.svg?branch=master)](http://codecov.io/github/snd/hinoki?branch=master)
[![Dependencies](https://david-dm.org/snd/hinoki.svg)](https://david-dm.org/snd/hinoki)

<!--
hinoki is a powerful yet simple asynchronous dependency injection system
designed to manage complexity in applications and (asynchronous) computation.
-->

**effective yet simple dependency injection and more for Node.js and browsers**

> Hinoki seems to be the least surprising IoC container available for Node.  
> I definitely do like its ascetic worldview.  
> Thanks a lot for this!  
> [andrey](https://github.com/snd/hinoki/issues/3)

<!--
cut right to the point:
why is this useful for me

main use case

you can also use it
-->

(web) applications are systems.
systems with many parts: functions, helpers, actions, objects, data, configuration.
parts depend on each other.
often asynchronously in the case of Node.js.
often in complex ways.
in Node.js they often depend on each other asynchronously.
often they depend on each other in complex ways.

such complex systems consisting of many interdependent parts can be simplified
by using dependency injection.

dependency injection can simplify such systems.

dependency injection is a simple idea:  
each part declares its dependencies (the other parts it needs).
there is a piece of code for constructing each part.
called a factory
parts of the system say which other parts they need.
then dependency injection makes sure they get them.

just by the name of their function parameter.
the injector then hands those dependencies to the parts that need them.

the injector !!!

clojure based dependency injection.
the wiring happens automatically.
manual wiring boilerplate disappears.
nothing is hardwired. everything is mockable.
every part is easy to test in isolation.

hinoki is an extremely simple and functional approach to dependency injection.
it supports usage patterns not possible with other dependency injection systems.

generalizes the concepts behind dependency injection.

you can use it for traditional dependency injection.
you can also do more and exiting things

[![Sauce Test Status](https://saucelabs.com/browser-matrix/hinoki.svg)](https://saucelabs.com/u/hinoki)


read on [stick around] for the scenic tour.

<!--
hinoki boils dependency injection down to the essentials:
no configuration, no XML, no OOP, no boilerplate.
-->

<!--
later add here
[i'm not convinced]
[i want examples]
[i want a guided tour]

for now there's just the guided tour

-->

hinoki is a bit like a [map](https://en.wikipedia.org/wiki/Associative_array)
with the addition that **values** can depend on each other.  

this
the dependency graph (which **values** depend on each other) is controllable programmatically.  
like a [map](https://en.wikipedia.org/wiki/Associative_array)
hinoki manages a mapping from **keys** to **values**.  
we can ask for a **key** and get a **value**.  
unlike a map:  
if we ask for a **key** that has no **value**, then
a user-provided **source** function is called.  
that **source** function doesn't return a **value** directly.  
instead it returns a **factory**,
which is simply a function that returns a **value**.  
hinoki looks at the **factory's** parameter names,
interprets them as **keys**,
looks up their **values**,
calls the factory with the **values** which returns a **value**.  
sources dynamically extend the keyspace managed by hinoki.

you can make a value depend on other values simply by

``` javascript
var factories = {
  six: function(one, two, three) {
    return one + two + three;
  }
}
```






like a [map](https://en.wikipedia.org/wiki/Associative_array)
we can use hinoki as a building block in solving a whole variety of problems.

we use it in the large to structure entire web applications.

we use it in the small to tame complex asynchronous I/O flows
*(you know... those where you do some async I/O that depends on three other 
async results and is needed by two other...)*

hinoki is an abstract and flexible tool.
when applied to the right problems it can reduce
incidental complexity and boilerplate,
make code more testable, easier to understand,
simpler, less complex and more elegant.

reading and understanding the rest of this readme should take less than 10 minutes.  
its goal is to make you thoroughly understand hinoki's interface and core concepts.  
hopefully enabling you to extrapolate to solve your own problems.  

[hinoki is inspired by prismatic's fantastic graph.](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife)

*hinoki takes its name from the hinoki cypress,
a tree that only grows in japan and is the preferred wood for building palaces,
temples and shrines.  
we hope hinoki becomes the building material for your digital palaces too !*

<!--
with these words the introduction ends

immediately show some code
-->

<!--

function implementations are systems too just with fewer parts.

in the large and in the small, hinoki can 

dependency injection is a simple concept.




you might have
an access control function `isUserAllowedToAccess
that depends on the `currentUser`, which depends on a function
`getUserById(id)` which depends on a `databaseConnectionPool` which
depends on some configuration `databaseUrl` which depends on the environment `env`.

parts are usually hardwired together.

using hinoki we treat them uniformly.


whenever you have a system (application, computation, query, ...) whose elements
(data, functions, ...) depend
on each other in complex and sometimes asynchronous ways
hinoki can help express in a simple, testable, elegant way.

hinoki is useful when your system, problem, application, or computation.
consists of multiple **_values_** that depend on each other.
especially if the elements are available asynchronously.
results of asynchronous i/o.
hinoki can allow

hinoki supports asynchroni... with promises.

a system could be an entire application, a query with many asynchronous parts
or
in any case hinoki

if you use hinoki in another interesting way i'd be happy to hear about it.

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

-->

<!--
whenever you have a system whose components depend on each other
in complex and/or asynchronous ways.
hinoki is useful in reducing 
complexity
-->

<!--

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

-->

<!--
possibly insert reference to fragments here
-->

<!--

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

-->

<!---

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

## get it

```
npm install hinoki
```

```javascript
var hinoki = require('hinoki');
```

```
bower install hinoki
```

[lib/hinoki.js](lib/hinoki.js) supports [AMD](http://requirejs.org/docs/whyamd.html).
if [AMD](http://requirejs.org/docs/whyamd.html) is not available it sets the global variable `hinoki`.

## keys and values

<!--
this is a short text that describes what will follow
-->

<!--
like a map hinoki is fairly abstract.
-->

<!--
if it doesn't please make an issue

most of the things you'll learn can be combined in ... ways.
extrapolate. use common sense.
if you have the feeling that something should work, but doesn't,
i'd appreciate it if you added an issue.

so you get a feeling of its general workings.

we'll start very simple
if you've read this (it only takes x minutes).
you know what you can do with hinoki.
if you'd rather see a full example
you'll know how to use hinoki.
-->

<!--
mark important sentences ("always") with an exclamation mark

make them bold
-->

like a [map](https://en.wikipedia.org/wiki/Associative_array)
hinoki manages a mapping from **keys** to **values**.

think of the **values** as the parts of your system.  
think of the **keys** as the names for those parts.

like a [map](https://en.wikipedia.org/wiki/Associative_array)
we can ask for a **value** that is associated with a given **key**:

``` javascript
var source = function() {};

var lifetime = {
  one: 1,
  two: 2,
  three: 3,
};

var key = 'three';

hinoki(source, lifetime, key).then(function(value) {
  assert(value === 3);
});
```

the first argument is the **source**.
[more on that in a bit.](#sources-and-factories)
here it does nothing.
it's not optional
don't worry about it for now.
we'll come to that in a bit.

the second argument is a **lifetime**.  
a **lifetime** is a plain-old-javascript-object that maps
**keys** to **values**.  
**lifetimes** store **values**.  
[we'll learn more about lifetimes later.](#lifetimes-in-depth)

the third argument is the **key** we want to get the **value** of.

if we ask for a **key** and a **value**
is present for that **key** in the **lifetime** then `hinoki` will
return a [promise](https://github.com/petkaantonov/bluebird) that resolves exactly to that **value** !

`hinoki` always returns a [promise](https://github.com/petkaantonov/bluebird) !

that code not very useful. we could have used `lifetime.three` directly.  
[we'll get to the useful stuff in a bit !](#sources-and-factories)

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

the **value** is always returned from the first **lifetime** having the **key** !

multiple **lifetimes** are really useful. [more on that later.](#lifetimes-in-depth)

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

hinoki has just parsed the **keys** from the function *parameter names*
and called the function with the **values** (associated with those **keys**) as *arguments*.

in this case `hinoki` returns a [promise](https://github.com/petkaantonov/bluebird) that resolves to the
**value** (or promise) returned by the function.

that's an improvement but still not really what hinoki is about.

let's get to that now !

## sources and factories

what if we ask for a value that is not present in the **lifetime(s)** ?
``` javascript
var lifetime = {
  one: 1,
  two: 2,
  three: 3,
};

hinoki(function() {}, lifetime, 'four').then(function(value) {
  /* this code is never reached */
});
```
the promise is rejected with an error:
```
Unhandled rejection NotFoundError: neither value nor factory found for `four` in path `four`
```

<!--
document error handling here
and reference longer error handling documentation
-->

<!--

fragments is a library that uses hinoki under the hood to make
webdevelopment 
-->

if there is no **value** for the **key** in any of the **lifetimes**
hinoki calls the **source** function with the **key** !

think of **source** as a fallback on missing **key** **value** mappings.

the **source** is not supposed to return a **value** directly.
instead the **source** is supposed to return a **factory** or `null`.

a **factory** is simply a function that returns a **value**.

returning `null` (`undefined` is fine too) signals hinoki
that the **source** can't return a factory that can make a **value** for that **key**.

**sources** make **factories**.  
**factories** make **values**.

**factories** declare **dependencies** through their *parameter names*:  
the *parameter names* of a **factory** function are
interpreted as **keys**. hinoki will get **values** for those **keys**
and call the **factory** with them as *arguments*.

<!--
different from a [map](https://en.wikipedia.org/wiki/Associative_array)
these levels of indirection allow us to
have **values** depend on other **values**
and provide  (similar to ruby's method missing).
-->

let's see an example:

``` javascript
var lifetime = {
  one: 1,
  two: 2,
  three: 3,
};

var source = function(key) {
  if (key === 'five') {
    return function(one, four) {
      return one + four;
    };
  }
  if (key === 'four') {
    return function(one, three) {
      return Promise.resolve(one + three);
    };
  }
};

hinoki(source, lifetime, 'five').then(function(value) {
  assert(value === 5);
  assert(lifetime.five === 5);
  assert(lifetime.four === 4);
});
```

there's a lot going on here. let's break it down.
you'll understand most of hinoki afterwards:

we want the **value** for the **key** `'five'`.  
hinoki immediately returns a [promise](https://github.com/petkaantonov/bluebird). it will resolve that [promise](https://github.com/petkaantonov/bluebird) with the **value** later.  
there is no **key** `'five'` in the **lifetime** so
hinoki calls our `source` function with the argument `'five'`.  
`source` returns the **factory** function for `'five'`.  
the **factory** for `'five'` has *parameter names* `'one'` and `'four'`.  
hinoki calls itself to get the **values** for `'one'` and `'four'`
such that it can call the **factory** with those **values**.  
`'one'` is easy. it's already in the **lifetime**.  
but there is no **key** `'four'` in the **lifetime** therefore
hinoki calls our `source` function again with the argument `'four'`.  
`source` returns the **factory** function for `'four'`.  
the **factory** for `'four'` has parameters `'one'` and `'three'`.  
hinoki calls itself to get the **values** for `'one'` and `'three'`.  
fortunately values for both `'one'` and `'three'` are already in the lifetime.  
hinoki can now call the **factory** for `'four'` with arguments `1` and `3`.  
the **factory** for `'four'` returns a promise.  

when a **factory** returns a promise hinoki must naturally
wait for the promise to be resolved before calling any
other **factories** that depend on that **value** !

at some point the promise for `'four'` resolves to `4`.  
hinoki can now continue making everything that depends on the **value** for `'four'`:

first hinoki sets `lifetime.four = 4`.

**values** returned from **factories** are stored/cached in the **lifetime** !  
what if we have multiple **lifetimes**? [the answer is very useful and worth its own section.](#lifetimes)

now hinoki can call the **factory** for `'five'` with arguments `1` and `4`.  
ince he **factory** for `'five'` doesn't return a promise hinoki doesn't have to wait.  
hinoki sets `lifetime.five = 5`.  
remember that promise hinoki has returned immediately ?
now that we have the **value** for **key** `'five'` hinoki resolves it with `5`.

that's it for the breakdown.  
you should now have a pretty good idea what hinoki does.  
keep in mind that this scales to any number of keys, values, factories,
lifetimes and dependencies !

<!--
**sources** make **factories**.  
**factories** make **values**.  
**lifetimes** store **values**.
-->

having to add an if-clause in the **source** for every **factory**
is not very convenient.  
fortunately there's much more to sources. read on !

## sources in depth

the first argument passed to `hinoki` is always interpreted as the **source**
and passed to `hinoki.source` internally.

`hinoki.source` takes either an object, a string, an array or a function.  
`hinoki.source` always returns a **source** function.

when `hinoki.source` is called with a function argument its simply returned.

### objects

if an object mapping **keys** to the **factories** for those **keys**
is passed to `hinoki.source` it is wrapped in a **source** function
that simply looks up the **key** in the object:

``` javascript
var lifetime = {
  one: 1,
  two: 2,
  three: 3,
};

var factories = {
  five: function(on, three) {
    return one + four;
  },
  four: function(one, three) {
    return Promise.resolve(one + three);
  },
};

hinoki(factories, lifetime, 'five').then(function(value) {
  assert(value === 5);
  assert(lifetime.five === 5);
  assert(lifetime.four === 4);
});
```

much more readable and maintainable than all those if-clauses we had before.

### strings

if a string is passed to `hinoki.source` it is interpreted as a filepath.

if the filepath points to a `.js` or `.coffee`
file `hinoki.source` will `require` it
and return a **source** function that looks up **keys**
in the `module.exports` returned by the require.

if the filepath points to a folder `hinoki.source` will
require all `.js` and `.coffee` files in that folder recursively.
other files are ignored.
all `module.exports` returned by the requires are merged into one object.
a **source** function is returned that looks up **keys**
in that object.

it is very easy to load **factories** from files that simply export
**factories** this way !

sources can also be strings.
in that case hinoki interprets them as filenames to require

this means that you can just drop your factories as exports
pull them all in and wire them up.

you could have all your factories as exports in a number
of 

your factories could then depend on other factories exported
by any other file in that directory.


<!--
this is the first useful level of indirection:
sources are for responding to values that are not present in lifetimes.
sources don't return a value directly.
they return a factory
factories return values.
this is the second useful level of indirection.
-->

<!--
this is the second level of indirection.
-->

### arrays

sources compose:  
if an array is passed to `hinoki.source` it is interpreted as an
array of potential **sources**.

this section needs work

<!--

an array could contain 
you can mix sources.

check out the appliation example for

its 


finally a source can be an array of sources

this allows you to mix and match sources.


what if you want to use multiple sources?
-->

### generator functions

this section needs work

<!--
finally

there's a lot you can do with sources.

method missing.
autogenerate.
check out [umgebung](http://github.com/snd/umgebung).

sources can generate factories for keys on the fly.
method missing.
check out [umgebung]() which parses environment variables
-->

### decorator functions

this section needs work

<!--
decorate to do tracing (checkout telemetry),
memoization, freezing, ...
-->

## lifetimes in depth

this section needs work

**lifetimes** store **values**.

why multiple lifetimes ?

because values 

there's only one application

but there are many requests

there are many events

many lifetimes

but you still want 

let's see an example:

request, response

fragments is with this idea at its core.

<!--
manage values that live for 
duration of a request or an event.

this enables per-request- and per-event-dependency-injection.
-->


## factories in depth

this section needs work

<!--

as the first

we could have multiple factories that return
promises for results of interdependent queries.

hinoki guarantees that the query is only executed once.

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

hinoki exports a single function which can be called
with [two or three arguments](#ways-to-call-hinoki).

if you still think i'd be happy 




keyspace.
set of keys.

-->

<!--
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

lifetimes manage state.
lifetimes manage how long state lives.
lifetimes manage the lifetime of certain state.

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

- [a functional data-driven approach with localized mutable state](#lifetimes)
- a simple carefully-designed (underlying) model
flexible core
a simple, carefully-designed and flexible core with many useful qualities

Use multiple lifetimes with different lifetimes that reference each Other

lifetimes with lower lifetimes can depend on lifetimes with higher lifetimes

A is active during a request but depends on some Things in b which lives through the entire process

hinoki lifetimes

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

-->

## changelog

future changes will be documented here

<!--
## how fast is this ?

version ... of hinoki
on a 2014 macbook air running iojs ... on date

lookups of 1 cached value

it should be fast enough
-->

<!--

### narratives


NARRATIVE

repetition

lifetimes and values
sources and factories

multiple lifetimes

request example

add headings later

end with sources

link things like

> in a bit

> later

> soon

-->


## [license: MIT](LICENSE)
