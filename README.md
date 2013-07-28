# hinoki

**magical inversion of control for nodejs**

hinoki manages complexity in large nodejs applications.

it was designed with great care to

hinoki is inspired by [prismatic's graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife) and [angular's dependency injection](http://docs.angularjs.org/guide/di).

### get started

##### install

```
npm install hinoki
```

**or**

put this line in dependencies section of your `package.json`:

```
"hinoki": "0.1.0"
```

then run:

```
npm install
```

##### require

```javascript
var hinoki = require('hinoki');
```

##### make a graph

lets make a simple graph:

```javascript
var graph = {
    a: function() {
        return 1;
    },
    b: function(a) {
        return a + 1;
    },
    c: function(a, b) {
        return a + b;
    }
};
```

`a`, `b` and `c` are the **nodes** of the graph.

every node has an associated function. lets call them **factories**.

the arguments to the factories declare the **dependencies** of each node:
`a` has no dependencies.
`b` depends on `a`.
`c` depends on `a` and `b`.

a factory returns an **instance** of a node when called with the **instances**
of the nodes which are its dependencies.

##### make a container

we need a place to put those instances.
this place is called a `scope`.

the pair of `graph` and `scope` is called a **container**. let's make one:

```javascript
var container = {
    graph: graph,
    scope: {}
};
```

if you omit the `scope` property hinoki will create one for you.

##### ask for a value

let's ask the container for the instance of node `c`:

```javascript
hinoki.inject(container, function(c) {
    console.log(c) // => 3
});
```

because we asked for `c`, which depends on `a` and `b`, hinoki has
made instances for `a` and `b` as well and added them to the scope:

```javascript
console.log(container.scope.a) // => 1
console.log(container.scope.b) // => 2
console.log(container.scope.c) // => 3
```

while `a` is a dependency of both `b` and `c`, the factory for `a` was only
called once. every node has at most one instance. the second time `a` needed
to be resolved it was already in scope.

**hinoki will only call a nodes factory function if the node has no instance yet.**

lets provide an instance directly:

```javascript
var container = {
    graph: graph,
    scope: {
        a: 3
    }
};

hinoki.inject(container, function(b) {
    console.log(b) // => 4
});
```

here we only asked for `b`. it was not necessary to resolve `c`:

```javascript
console.log(container.scope.a) // => 1
console.log(container.scope.b) // => 2
console.log(container.scope.c) // => undefined
```

**hinoki will only call the factories for nodes that you ask for or that the nodes
you ask for depend on.**

##### promises

if a factory returns a [q promise](https://github.com/kriskowal/q)
hinoki will wait until the promise is resolved.

see [example/async.js](example/async.js).

##### hooks

using hooks you can change the error handling of any container.
you can also use them to add debugging to a container.

let's log every time a promise is returned from a factory:

```javascript
var container = {
    hooks: {
        promise: function(chain, promise) {
            console.log('factory for service ' + chain[id] + ' returned promise' + promise);
        };
    }
};
```

see [src/hooks.coffee](src/hooks.coffee) for all available hooks
and their default implementations.

### great! can i do anything useful with it?

### automated dependency injection

just register all your services in a graph object

example dependency injection

just a counter example

architectural style that is very well testable

##### computation

describe a computation in terms of the data dependencies.

```javascript
var factories = {
    count: function(numbers) {
        return numbers.length;
    },
    mean: function(numbers, count) {
        var reducer = function(acc, x) {
            return acc + x;
        };
        return numbers.reduce(reducer, 0) / count;
    },
    meanOfSquares: function(numbers, count) {
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

once the mean factory has been called
the mean instance is added to container.instances
and will not be computed again for this container.

only the factory functions needed to get instances of
the dependencies will be called.

we can see that the mean needs the series and the count

lets build a container where we provide the missing dependency
explicitely.

```
var container = {
    factories: factories,
    instances: {
        numbers: [1, 2, 3, 6]
    }
};
```

lets ask for the mean:

```javascript
hinoki.inject(container, function(mean) {
    console.log(mean);  // -> 3
});
```

if you ask for the mean, the mean of squares will not be computed.
if you ask for the variance the count will only be computed once.

**hinoki will only call the factory for services which don't have an instance**

once a factory has been called, th
and it will not be called again.

**hinoki will call any factory at most once per container.**


the instances

note that the meanOfSquares and variance have not been computed
because we only asked for the mean and the mean only depends
on the count.

all instances are added to container

the factory function will not be called again.

now run the same computation with another series:

```javascript
var container2 = {
    factories: factories,
    instances: {
        xs: [1, 2, 3, 6]
    }
};
```

lets ask for the variance:

```javascript
hinoki.inject(container2, function(variance) {
    console.log(variance);  // -> 3.5
});
```

### closure factories

closures are used to...

can be used to construct

```javascript
var factories = {
};

var container = {
    factories: factories,
    instances: {}
};
```

### multiple containers

different lifetimes

database connections. data access methods.

```javascript
hinoki.inject([c1, c2, c3], function(a, b, c) {

});
```

we want these to only be created once

some parts that stay the same during the entire duration of the application
and some parts change but should use those other parts.

the dependencies are looked up left to right

decreasing lifetime

this allows you to attach stuff

describe this in a good example

### license: MIT
