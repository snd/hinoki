# hinoki

**magical inversion of control for nodejs**

hinoki manages complexity in large nodejs applications.

Keep it as simple and minimal as possible
Open
Easy to understand
Easy to monkeypatch

Which Problem Is it trying to solve?
application structure, testability,
complex interdependent async loads

*link here to the usage examples below*

hinoki leads to shorter and simpler code in a variety of cases:

computation example

dependency injection

only computes whats needed

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

### simple usage

```javascript
var hinoki = require('hinoki');

var factories = {
    a: function() {
        return 1;
    },
    b: function(a) {
        return a + 1;
    },
    c: function(a, b) {
        return a + b + 1;
    }
};

var container = {
    factories: factories,
    instances: {},
};

hinoki.inject(container, function(a, b, c) {
    console.log(a);     // -> 1
    console.log(b);     // -> 2
    console.log(c);     // -> 4
});
```

##### seed values

```javascript
var hinoki = require('hinoki');

var factories = {
    c: function(a, b) {
        return a + b + 1;
    }
};

var container = {
    factories: factories,
    instances: {
        a: 1,
        b: 2
    },
    config: {}
};

hinoki.inject(container, function(a, b, c) {
    console.log(a);     // -> 1
    console.log(b);     // -> 2
    console.log(c);     // -> 3
});
```

### computation

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

var container = {
    factories: factories,
    instances: {
        xs: [1, 2, 3, 6]
    }
};

hinoki.inject(container, function(mean) {
    console.log(mean);  // -> 3
});
```

if you ask for the mean, the mean of squares will not be computed.
if you ask for the variance the count will only be computed once.

if you dont pass in a instances one will be created for you.

### asynchronous computations

if a factory returns a [q promise](https://github.com/kriskowal/q)
hinoki will wait until the promise is resolved.

hinoki can make complex async flows more managable.

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

```javascript

```

### multiple containers

```javascript
hinoki.inject([c1, c2, c3], function(a, b, c) {

});
```

some parts that stay the same during the entire duration of the application
and some parts change but should use those other parts.

closure factories

the dependencies are looked up left to right

decreasing lifetime

this allows you to attach stuff

describe this in a good example

### hooks

provide all the necessary context

default behaviour is implemented using hooks. you can overwrite default behaviour.

error handling is per container

mainly used for debugging

inject will handle errors thrown in factory functions or rejected promises

do distinguish both!!!!

defaultHooks

// when a new instance needs to be created
config.onRequire = function(id, factory, requiringId, requiringFactory) {

};

// when an instance was created and is ready to be set on the instances
config.onRegister = function(id, instances, instance) {
    instances[id] = instance;
};

config.onInject = function(id, factory, instances) {
    factory.apply(undefined, instances);
};

if you provide an object

hinoki will use it to 

hinoki will cache 

or you provide these values already hinoki will

### terminology

##### service

a piece of data, function Or api that. An Interface, contract
a service can be anything, a simple value, an object, a function, an object with several functions.
a service provides certain functionality that other services might need.

##### id

a string that uniquely identifies a service. the "name" of the service.

##### dependency

the id of a service

**dependency** - 

**factory** - a function which takes **dependencies** as arguments and returns an **instance**.

**factories** - an object

**instance** -

**instances** - an object with properties where a key that is an *id* is associated  with an **instance** of that service.
*used for the*

**seed** - an instance inside a instances without a corresponding factory.

*used for bootstrapping and testing*

**container** manages services, factories, instances, configuration, lifetime

**lifetime**

### license: MIT

### todo

readme
refactor and polish

(symetric errors and hooks tests)
(test order)
(inject is not such a great name)
