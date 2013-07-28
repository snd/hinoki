# hinoki

**magical inversion of control for nodejs**

hinoki manages complexity in large nodejs applications.

describe dependency graphs.
query them.
resolve automatically.

hinoki leads to shorter and simpler code in a variety of cases:

dependency injection

hinoki can make complex async flows more managable.

hinoki is inspired by [prismatic's graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife) and [angular's dependency injection](http://docs.angularjs.org/guide/di).

crafted with great care.

it can be used to describe complex closure ...
and then resolve them repeatedly with different values

### how do i get started?

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

##### lets build a simple graph

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

`graph` is a dependency graph with three nodes.
`b` depends on `a` because `a` is an argument to `b`s function.
`c` depends on `a` and `b`.

##### lets ask for a value from the graph



##### 

```javascript
var container = {
    graph: graph,
    scope: {
        a: 3
    }
}
```

```javascript
hinoki.inject(container, function(c) {
    console.log(c) // => 7
});
```

### great! can i do anything useful with it?

there are at least three cases where hinoki can lead to simpler and shorter code:



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

### async

if a factory returns a [q promise](https://github.com/kriskowal/q)
hinoki will wait until the promise is resolved.

```javascript
var dns = require('dns');

var q = require('q');
var hinoki = require('hinoki');

var factories = {
    addresses: function(domain) {
        // here we use q.nfcall to return a promise
        // for a function that takes a nodejs style callback
        return q.nfcall(dns.resolve4, domain);
    },
    domains: function(addresses) {
        return q.all(addresses.map(function(address) {
            return q.nfcall(dns.reverse, address);
        }));
    }
};

var container = {
    factories: factories,
    instances: {
        domain: 'www.google.com'
    }
};

hinoki.inject(container, function(domains) {
    console.log(domains);
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

### hooks

hooks allow you to change the error handling and add debugging to any container.

example: log every time a promise is returned from a factory:

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

### license: MIT
