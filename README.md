# hinoki

magical inversion of control for nodejs.

hinoki is a tool to manage complexity in large nodejs applications.

Keep it as simple and minimal as possible
Open
Easy to understand
Easy to monkeypatch

Which Problem Is it trying to solve?
application structure, testability,
complex interdependent async loads

### use cases

hinoki leads to shorter and simpler code in a variety of cases:

- make computations with many interrelated
cache results which are needed multiple times

- services consumed by hinoki are inherently very well testable.

to compose large applications.

with hinoki you can theoretically 

COMPOSABILITY

hinoki is inspired by [prismatic's graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife) and [angular's dependency injection](http://docs.angularjs.org/guide/di).

crafted with great care.

even with lots of asynchronous calls

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

**scope** - an object with properties where a key that is an *id* is associated  with an **instance** of that service.
*used for the*

**seed** - an instance inside a scope without a corresponding factory.

*used for bootstrapping and testing*

**container** manages services, factories, scope, configuration, lifetime

**lifetime**

### use

##### simple

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
    scope: {},
    config: {}
};

hinoki.inject(container, function(a, b, c) {
    console.log(a);     // -> 1
    console.log(b);     // -> 2
    console.log(c);     // -> 3
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
    scope: {
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

##### async computations

##### multiple containers

### multiple containers

```javascript
hinoki.inject([c1, c2, c3], function(a, b, c) {

});
```

the dependencies are looked up right to left (nearest to farest from factory)

decreasing lifetime

this allows you to attach stuff

describe this in a good example

#####

If a Factory returns a promise hinoki will wait until the promise Is resolved

can also be used to make complex async flows more managable

use `q.nfcall` for callback style functions

```javascript
factories.async = function() {
    q.nfcall();
};
```

if hinoki encounters a service somewhere in its dependencies then there is a loop

### hooks

provide all the necessary context

default behaviour is implemented using hooks. you can overwrite default behaviour.

error handling is per container

mainly used for debugging

inject will handle errors thrown in factory functions or rejected promises

do distinguish both!!!!

also dont depend on q

allow that callback style

```javascript
config.onError = function(id, factory, err) {
    throw new Error('hinoki: error instantiating service ' + id + ': ' + err.message);
};

config.onCircular = function(circularIds) {
    throw new Error('hinoki: circular dependency ' + circularIds.join(' <- '));
};

// when a new instance needs to be created
config.onRequire = function(id, factory, requiringId, requiringFactory) {

};

// when an instance was created and is ready to be set on the scope
config.onRegister = function(id, scope, instance) {
    scope[id] = instance;
};

config.onInject = function(id, factory, instances) {
    factory.apply(undefined, instances);
};

config.onNotFound = function(id, parent) {
    if (!parentContainer) throw new Error('hinoki: not found ' + id);
};
```

if you provide an object

hinoki will use it to 

hinoki will cache 


or you provide these values already hinoki will

### api

returns the ids of the dependencies of a factory function:

```javascript
hinoki.parseDependencies(function(a, b, c) {});     // -> ['a', 'b', 'c']
```

### license: MIT
