# hinoki

**magical inversion of control for nodejs**

hinoki manages complexity in large nodejs applications.

data dependencies.

Which Problem Is it trying to solve?
application structure, testability,
complex interdependent async loads

*link here to the usage examples below*

hinoki leads to shorter and simpler code in a variety of cases:

dependency injection

hinoki can make complex async flows more managable.

- make computations with many interrelated
cache results which are needed multiple times

- services consumed by hinoki are inherently very well testable.

to compose large applications.

with hinoki you can theoretically 

COMPOSABILITY

hinoki is inspired by [prismatic's graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife) and [angular's dependency injection](http://docs.angularjs.org/guide/di).

crafted with great care.

even with lots of asynchronous calls

it can be used to describe complex closure ...
and then resolve them repeatedly with different values

### install

```
npm install hinoki
```

OR

put this line into the dependencies section of your `package.json`:

```
"hinoki": "0.1.0"
```

and then run:

```
npm install
```


### require

```javascript
var hinoki = require('hinoki');
```

### the basics

a **service** is
a piece of data, function Or api that. An Interface, contract
a service can be anything, a simple value, an object, a function, an object with several functions.
a service provides certain functionality that other services might need.

an **id** is a string that uniquely identifies a service. it's the *name* of the service.

an instance is a realized **service**

a **factory** is a function which takes **dependencies** as arguments and returns an **instance**.

**dependencies**

**dependency** - 


**factories** - an object

**instances** - an object with properties where a key that is an *id* is associated  with an **instance** of that service.
*used for the*

**seed** - an instance inside a instances without a corresponding factory.

*used for bootstrapping and testing*

**container** manages services, factories, instances, configuration, lifetime

**lifetime**


### computation

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

hinoki.inject(container, function(mean) {
    console.log(mean);  // -> 3
});
```

note that the meanOfSquares and variance have not been computed
because we only asked for the mean and the mean only depends
on the count.

now run the same computation with another series:

```javascript
var container2 = {
    factories: factories,
    instances: {
        xs: [1, 2, 3, 6]
    }
};

hinoki.inject(container2, function(variance) {
    console.log(mean);  // -> 3
});
```

if you ask for the mean, the mean of squares will not be computed.
if you ask for the variance the count will only be computed once.

if you dont pass in a instances one will be created for you.

### async

if a factory returns a [q promise](https://github.com/kriskowal/q)
hinoki will wait until the promise is resolved.

```javascript
var dns = require('dns');

var q = require('q');
var hinoki = require('hinoki');

var factories = {
    addresses: function(domain) {
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

use `q.nfcall` for callback style functions.

### closure factories

closures are used to...

can be used to construct

```javascript

```

### multiple containers

different lifetimes



```javascript
hinoki.inject([c1, c2, c3], function(a, b, c) {

});
```

some parts that stay the same during the entire duration of the application
and some parts change but should use those other parts.

the dependencies are looked up left to right

decreasing lifetime

this allows you to attach stuff

describe this in a good example

hinoki will cache 

or you provide these values already hinoki will


### hooks

hooks can 

a can be changed per container

see [src/hooks.coffee](src/hooks.coffee) for all possible hooks
and their default implementations.

for instance to log every time a promise is returned from a factory:

```javascript
var container = {
    hooks: {
        promise: function(chain, promise) {
            console.log('factory for service ' + chain[id] + ' returned promise' + promise);
        };
    }
};
```

this will

### license: MIT
